import cooler
import numpy as np
import pandas as pd
import logging
import os
import sys
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ── Configuration ─────────────────────────────────────────────────────────────

# RES         = 5000
# PATH_ES     = "ES_lib21_22_5kb.cool"
# PATH_120H   = "120h_lib25_5kb.cool"
# OUT_DIFF    = "results/cooler2_120h_minus_ES.cool"
# OUT_LOG2    = "results/cooler2_log2ratio_120h_over_ES.cool"
# PSEUDOCOUNT = 1

# ── Helpers ───────────────────────────────────────────────────────────────────

def fetch_balanced(clr: cooler.Cooler, chrom: str) -> np.ndarray:
    """
    Return the balanced matrix for *chrom*.
    NaNs are kept as NaN — they mark bins with no coverage and must NOT
    be coerced to 0, which would produce spurious large differences.
    """
    mat = clr.matrix(balance=True).fetch(chrom).astype(np.float64)
    return mat   # NaNs preserved intentionally


def matrix_to_pixels(mat: np.ndarray, offset: int) -> pd.DataFrame:
    """
    Convert an upper-triangle dense matrix to a COO pixel table.
    Drops NaN and zero entries — only real, finite, non-zero contacts stored.
    """
    i_idx, j_idx = np.triu_indices(mat.shape[0])
    values = mat[i_idx, j_idx]

    # keep only finite, non-zero pixels
    mask = np.isfinite(values) & (values != 0)

    return pd.DataFrame({
        "bin1_id": (i_idx[mask] + offset).astype(np.int64),
        "bin2_id": (j_idx[mask] + offset).astype(np.int64),
        "count":   values[mask].astype(np.float32),
    })


def write_cool(output_path: str, clr_ref: cooler.Cooler, matrix_by_chr: dict, RES, PATH_ES, PATH_120H) -> None:
    bins = clr_ref.bins()[["chrom", "start", "end"]][:]

    # precompute global bin offsets per chrom
    chrom_offsets = {}
    offset = 0
    for chrom in clr_ref.chromnames:
        chrom_offsets[chrom] = offset
        offset += clr_ref.extent(chrom)[1] - clr_ref.extent(chrom)[0]

    pixel_chunks = []
    for chrom in clr_ref.chromnames:
        if chrom not in matrix_by_chr:
            log.warning("Skipping missing chrom: %s", chrom)
            continue
        pix = matrix_to_pixels(matrix_by_chr[chrom], chrom_offsets[chrom])
        pixel_chunks.append(pix)
        log.info("  %s: %d pixels", chrom, len(pix))

    all_pixels = pd.concat(pixel_chunks, ignore_index=True).sort_values(
        ["bin1_id", "bin2_id"]
    )

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    Path(output_path).unlink(missing_ok=True)

    cooler.create_cooler(
        cool_uri=output_path,
        bins=bins,
        pixels=all_pixels,
        dtypes={"count": np.float32},
        metadata={"resolution": int(RES), "source_ES": PATH_ES, "source_120h": PATH_120H},
        ordered=True,
    )
    log.info("Saved → %s  (%d pixels total)", output_path, len(all_pixels))


# ── Main ──────────────────────────────────────────────────────────────────────

def main(PATH_ES, PATH_120H, OUT_DIFF, OUT_LOG2, PSEUDOCOUNT=1) -> None:
    log.info("Loading coolers …")
    clr_ES   = cooler.Cooler(PATH_ES)
    clr_120h = cooler.Cooler(PATH_120H)

    RES = clr_ES.binsize
    assert clr_ES.binsize == clr_120h.binsize == RES
    assert list(clr_ES.chromnames) == list(clr_120h.chromnames)

    diff_by_chr      = {}
    log2ratio_by_chr = {}

    for chrom in clr_ES.chromnames:
        log.info("Processing %s …", chrom)

        mat_ES   = fetch_balanced(clr_ES,   chrom)
        mat_120h = fetch_balanced(clr_120h, chrom)

        # Both matrices keep NaN where bins have no coverage.
        # Arithmetic between two NaN-aware arrays propagates NaN correctly:
        # NaN in either sample → NaN in output → dropped when writing pixels.

        # Signed difference: positive = gained at 120h, negative = lost at 120h
        diff_by_chr[chrom] = mat_120h - mat_ES

        # Log2 ratio: positive = enriched at 120h, negative = depleted at 120h
        log2ratio_by_chr[chrom] = np.log2(
            (mat_120h + PSEUDOCOUNT) / (mat_ES + PSEUDOCOUNT)
        )

    log.info("Writing difference cool …")
    write_cool(OUT_DIFF, clr_ES, diff_by_chr, RES, PATH_ES, PATH_120H)

    log.info("Writing log2-ratio cool …")
    write_cool(OUT_LOG2, clr_ES, log2ratio_by_chr, RES, PATH_ES, PATH_120H)

    log.info("Done.")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python cooler_diff.py <cool1> <cool2>")
        sys.exit(1)
    
    PATH_ES = sys.argv[1]
    PATH_120H = sys.argv[2]
    
    os.mkdir("output")
    OUT_DIFF = "output/diff.cool"
    OUT_LOG2 = "output/log2ratio.cool"
    PSEUDOCOUNT = 1
    
    main(PATH_ES, PATH_120H, OUT_DIFF, OUT_LOG2, PSEUDOCOUNT)