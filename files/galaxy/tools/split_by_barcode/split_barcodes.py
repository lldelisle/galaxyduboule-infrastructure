#!/usr/bin/env python3
# split_barcodes.py

import argparse
import csv
import gzip
import pandas as pd
import scipy.io
import os
from datetime import datetime

parser = argparse.ArgumentParser(description="Split STARsolo/10X output by barcode marker")
parser.add_argument('--manifest', required=True,
                     help="TSV file with columns: pool_id, file_identifier, file_path")
parser.add_argument('--output_dir', required=True, help="Output directory")
parser.add_argument('--sample_map', required=True, help="Sample mapping file (name:marker pairs)")
args = parser.parse_args()

os.makedirs(args.output_dir, exist_ok=True)

ROLE_KEYWORDS = {
    'barcodes': ('barcode',),
    'genes': ('gene', 'feature'),
    'matrix': ('matrix', 'matrices'),
}


def identify_role(file_identifier):
    name = file_identifier.lower()
    for role, keywords in ROLE_KEYWORDS.items():
        if any(keyword in name for keyword in keywords):
            return role
    return None


def is_mtx_format(path):
    # Galaxy datasets are generic .dat files, so we can't rely on the
    # extension - sniff the MatrixMarket header instead.
    opener = __import__('gzip').open if path.endswith('.gz') else open
    with opener(path, 'rt') as f:
        return f.readline().startswith('%%MatrixMarket')


def load_matrix(path):
    try:
        if is_mtx_format(path):
            X = scipy.io.mmread(path).T.tocsr()
            matrix_type = "MTX (sparse)"
        else:
            X = pd.read_csv(
                path,
                sep='\t',
                index_col=0,
                compression='gzip' if path.endswith('.gz') else None
            )
            matrix_type = "TSV (dense)"
        return X, matrix_type
    except Exception as e:
        print(f"✗ Error loading matrix: {e}")
        exit(1)


# === PARSE SAMPLE MAPPING ===
samples = {}  # {custom_name: marker}

with open(args.sample_map, 'r') as f:
    for line in f:
        line = line.strip()
        if line:
            sample_name, marker = line.split(':')
            samples[sample_name] = marker

# === PARSE MANIFEST ===
# pools[pool_id][role] = file_path
pools = {}
with open(args.manifest, 'r') as f:
    for row in csv.reader(f, delimiter='\t'):
        if not row:
            continue
        pool_id, file_identifier, file_path = row
        role = identify_role(file_identifier)
        if role is None:
            print(f"✗ Could not determine role (barcodes/genes/matrix) for '{file_identifier}' in {pool_id}")
            exit(1)
        pools.setdefault(pool_id, {})[role] = file_path

print("=" * 60)
print("STARsolo/10X Barcode Splitter")
print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 60)
print(f"\nPools in batch: {len(pools)}")
print("\nSample Mapping (Internal):")
for name, marker in samples.items():
    print(f"  {name:20} ← Marker: {marker}")

overall_summary = []

for pool_id, files in pools.items():
    print("\n" + "=" * 60)
    print(f"Pool: {pool_id}")
    print("=" * 60)

    try:
        barcodes = pd.read_csv(
            files['barcodes'],
            sep='\t',
            header=None,
            compression='gzip' if files['barcodes'].endswith('.gz') else None
        )
        print(f"  Barcodes: {len(barcodes):,} cells")
    except Exception as e:
        print(f"✗ Error loading barcodes for {pool_id}: {e}")
        exit(1)

    try:
        genes = pd.read_csv(
            files['genes'],
            sep='\t',
            header=None,
            compression='gzip' if files['genes'].endswith('.gz') else None
        )
        print(f"  Genes: {len(genes):,} genes")
    except Exception as e:
        print(f"✗ Error loading genes for {pool_id}: {e}")
        exit(1)

    X, matrix_type = load_matrix(files['matrix'])
    print(f"  Matrix: {X.shape[0]:,} cells × {X.shape[1]:,} genes ({matrix_type})")

    print("\nSplitting by barcode marker (positions 8-9)...")

    total_cells = 0

    for sample_name, marker in samples.items():
        try:
            mask = barcodes[0].str.slice(7, 9) == marker
            indices = mask[mask].index.tolist()

            outdir = os.path.join(args.output_dir, pool_id, sample_name)

            if len(indices) > 0:
                print(f"\n→ {sample_name:20} (marker: {marker})")
                print(f"  {len(indices):,} cells ({len(indices)/len(barcodes)*100:.1f}%)")

                if isinstance(X, pd.DataFrame):
                    X_sample = X.iloc[indices, :]
                else:
                    X_sample = X[indices, :]

                barcodes_sample = barcodes.iloc[indices]

                os.makedirs(outdir, exist_ok=True)

                barcodes_file = os.path.join(outdir, "barcodes.tsv.gz")
                barcodes_sample.to_csv(barcodes_file, sep='\t', header=False, index=False, compression='gzip')

                genes_file = os.path.join(outdir, "genes.tsv.gz")
                genes.to_csv(genes_file, sep='\t', header=False, index=False, compression='gzip')

                if isinstance(X_sample, pd.DataFrame):
                    matrix_file = os.path.join(outdir, "matrix.tsv.gz")
                    X_sample.to_csv(matrix_file, sep='\t', compression='gzip')
                else:
                    with gzip.open(os.path.join(outdir, "matrix.mtx.gz"), 'wb') as gz_file:
                        scipy.io.mmwrite(gz_file, X_sample.T.tocoo())

                print(f"     {pool_id}/{sample_name}/{{barcodes.tsv.gz,genes.tsv.gz,matrix.*gz}}")

                total_cells += len(indices)
                overall_summary.append({
                    'pool_id': pool_id,
                    'custom_name': sample_name,
                    'marker': marker,
                    'n_cells': len(indices),
                    'pct_cells': len(indices)/len(barcodes)*100
                })
            else:
                print(f"\n⚠ {sample_name:20} (marker: {marker})")
                print(f"  No cells found!")
                overall_summary.append({
                    'pool_id': pool_id,
                    'custom_name': sample_name,
                    'marker': marker,
                    'n_cells': 0,
                    'pct_cells': 0
                })
        except Exception as e:
            print(f"\n✗ Error processing {pool_id}/{sample_name}: {e}")
            exit(1)

    print(f"\nTotal cells input ({pool_id}): {len(barcodes):,}")
    print(f"Total cells output ({pool_id}): {total_cells:,}")
    print(f"Unassigned ({pool_id}): {len(barcodes) - total_cells:,}")

# === SUMMARY ===
print("\n" + "=" * 60)
print("BATCH SUMMARY")
print("=" * 60)

summary_file = os.path.join(args.output_dir, "split_summary.log")
with open(summary_file, 'w') as f:
    f.write("STARsolo/10X Barcode Splitter Summary\n")
    f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("=" * 60 + "\n\n")
    f.write(f"Pools in batch: {len(pools)}\n\n")
    f.write("Pool\tSplit Name\tMarker\tCells\t%\n")
    for row in overall_summary:
        f.write(f"{row['pool_id']}\t{row['custom_name']}\t{row['marker']}\t{row['n_cells']}\t{row['pct_cells']:.2f}\n")

print("\n Summary written to: split_summary.log")
print(f"\n All done! {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
