#!/usr/bin/env python3
from bioblend.galaxy import GalaxyInstance
import sys
import os
import time

gi = GalaxyInstance("https://galaxyduboule.epfl.ch", key=sys.argv[1])
my_library_id = '03501d7626bd192f'
s3_dir = '/data/mount_s3/perso_storage/useful_datasets/'
local_dir = 'useful_datasets'
my_folder = 'useful_datasets'
urls = {'https://zenodo.org/record/7510406/files/mergeOverlapGenesOfFilteredTranscriptsOfMus_musculus.GRCm38.102_ExonsCDSOnly_UCSC.gtf.gz?download=1':'mergeOverlapGenesOfFilteredTranscriptsOfMus_musculus.GRCm38.102_ExonsCDSOnly_UCSC.gtf',
        'https://zenodo.org/record/3457880/files/3M-february-2018.txt.gz': 'cellranger_barcodes_3M-february-2018.txt',
        'https://zenodo.org/record/7510797/files/mergeOverlapGenesOfFilteredTranscriptsOfMus_musculus.GRCm39.108_ExonsCDSOnly_UCSC.gtf.gz?download=1': 'mergeOverlapGenesOfFilteredTranscriptsOfMus_musculus.GRCm39.108_ExonsCDSOnly_UCSC.gtf'}

if f"/{my_folder}" in [mf['name'] for mf in gi.libraries.get_folders(my_library_id)]:
  # I delete them:
  for my_folder_id in [f['id'] for f in gi.libraries.get_folders(my_library_id, name=f"/{my_folder}")]:
    print("Removing existing folder")
    gi.folders.delete_folder(my_folder_id)

# I create a new one:
my_folder_id = gi.libraries.create_folder(my_library_id, my_folder)[0]['id']

# Put what is on s3 in the library:
print("Transfer from s3 to new folder")
gi.libraries.upload_from_galaxy_filesystem(my_library_id,
                                           filesystem_paths=s3_dir,
                                           folder_id=my_folder_id,
                                           link_data_only=True)
# Put what is in the local dir:
print("Transfer from local dir to new folder")
for f in os.listdir(local_dir):
  gi.libraries.upload_file_from_local_path(my_library_id,
                                           file_local_path=os.path.join(local_dir, f),
                                           folder_id=my_folder_id)
print("Download url to new folder")
for url in urls:
  dataset = gi.libraries.upload_file_from_url(my_library_id,
                                              file_url=url,
                                              folder_id=my_folder_id)

# I delete the existing histories:
for history in gi.histories.get_histories(name=my_folder):
  gi.histories.delete_history(history['id'])

# Create a history:
my_history = gi.histories.create_history(name=my_folder)
gi.histories.copy_content(my_history['id'], my_folder_id, source='library_folder')

while len(gi.histories.show_history(my_history['id'])['state_ids']['new']) > 0:
  print("Waiting a minute for new datasets")
  time.sleep(60)

while len(gi.histories.show_history(my_history['id'])['state_ids']['upload']) > 0:
  print("Waiting a minute for upload datasets")
  time.sleep(60)

while len(gi.histories.show_history(my_history['id'])['state_ids']['queued']) > 0:
  print("Waiting a minute for queued datasets")
  time.sleep(60)

while len(gi.histories.show_history(my_history['id'])['state_ids']['running']) > 0:
  print("Waiting a minute for running datasets")
  time.sleep(60)

# Rename the urls:
for dataset_id in gi.histories.show_history(my_history['id'])['state_ids']['ok']:
  if gi.datasets.show_dataset(dataset_id)['name'] in urls:
    print(f"Waiting for {gi.datasets.show_dataset(dataset_id)['name']}")
    gi.datasets.wait_for_dataset(dataset_id)
    gi.histories.update_dataset(my_history['id'], dataset_id, name=urls[gi.datasets.show_dataset(dataset_id)['name']])

# Make it public:
gi.histories.update_history(my_history['id'], published=True)
