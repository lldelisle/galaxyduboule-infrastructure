#!/usr/bin/env python3
from bioblend.galaxy import GalaxyInstance
import sys

gi = GalaxyInstance("https://galaxyduboule.epfl.ch", key=sys.argv[1])
my_library_id = '03501d7626bd192f'
tool_data_dir = '/data/galaxy/galaxy/var/tool-data/'
my_folder = 'genomes_fa_len'

if f"/{my_folder}" in [mf['name'] for mf in gi.libraries.get_folders(my_library_id)]:
  # I delete them:
  for my_folder_id in [f['id'] for f in gi.libraries.get_folders(my_library_id, name=f"/{my_folder}")]:
    gi.folders.delete_folder(my_folder_id)

# I create a new one:
my_folder_id = gi.libraries.create_folder(my_library_id, my_folder)[0]['id']

# Put all fasta and length in the library:
my_genomes = gi.genomes.get_genomes()
for my_genome, _ in my_genomes:
  if my_genome != 'unspecified (?)':
    print(my_genome)
    # Upload the fasta
    gi.libraries.upload_from_galaxy_filesystem(my_library_id,
                                               filesystem_paths=f"{tool_data_dir}/{my_genome}/seq/",
                                               folder_id=my_folder_id,
                                               file_type='fasta',
                                               dbkey=my_genome,
                                               link_data_only=True)
    # Upload the length
    gi.libraries.upload_from_galaxy_filesystem(my_library_id,
                                               filesystem_paths=f"{tool_data_dir}/{my_genome}/len/",
                                               folder_id=my_folder_id,
                                               file_type='tabular',
                                               dbkey=my_genome,
                                               link_data_only=True)

# I delete the existing histories:
for history in gi.histories.get_histories(name=my_folder):
  gi.histories.delete_history(history['id'])

# Create a history:
my_history = gi.histories.create_history(name=my_folder)
gi.histories.copy_content(my_history['id'], my_folder_id, source='library_folder')
# Make it public:
gi.histories.update_history(my_history['id'], published=True)
