#!/usr/bin/env python3
from bioblend.galaxy import GalaxyInstance, tool_data
import sys

gi = GalaxyInstance("http://galaxyduboule.college-de-france.fr", key=sys.argv[1])
my_library_id = '03501d7626bd192f'
tool_data_dir = '/data/galaxy/galaxy/var/tool-data/genomes/'
my_folder = 'genomes_fa_len'

cvmfs_genomes = ['mm10', 'mm39']

if f"/{my_folder}" in [mf['name'] for mf in gi.libraries.get_folders(my_library_id)]:
  # I delete them:
  for my_folder_id in [f['id'] for f in gi.libraries.get_folders(my_library_id, name=f"/{my_folder}")]:
    gi.folders.delete_folder(my_folder_id)

# I create a new one:
my_folder_id = gi.libraries.create_folder(my_library_id, my_folder)[0]['id']

# Put all fasta and length in the library:
my_genomes = gi.genomes.get_genomes()
# Now there are so many genomes that we need to restrict them
# to the one installed manually
# and the one manually sets:
my_fasta_table = tool_data.ToolDataClient(gi).show_data_table("all_fasta")
my_fasta_files_dic = {v[0]:v[-1] for v in my_fasta_table['fields']}
my_len_table = tool_data.ToolDataClient(gi).show_data_table("__dbkeys__")
my_len_files_dic = {v[0]:v[-1] for v in my_len_table['fields']}

for my_genome, my_dbkey in my_genomes:
  if my_genome != 'unspecified (?)' and (my_dbkey in cvmfs_genomes or my_fasta_files_dic.get(my_dbkey, '').startswith(tool_data_dir)):
    print(my_genome)
    # Upload the fasta
    if my_dbkey in my_fasta_files_dic:
      gi.libraries.upload_from_galaxy_filesystem(my_library_id,
                                                 filesystem_paths=my_fasta_files_dic.get(my_dbkey),
                                                 folder_id=my_folder_id,
                                                 file_type='fasta',
                                                 dbkey=my_dbkey,
                                                 link_data_only=True)
    # Upload the length
    if my_dbkey in my_len_files_dic:
      gi.libraries.upload_from_galaxy_filesystem(my_library_id,
                                                 filesystem_paths=my_len_files_dic.get(my_dbkey),
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
