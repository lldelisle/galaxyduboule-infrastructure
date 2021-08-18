#!/bin/env python

import yaml
import xml.etree.ElementTree as ET
from collections import defaultdict
import re
import os
import sys
import argparse
import itertools
from copy import deepcopy

def main():

    VERSION = 0.2

    parser = argparse.ArgumentParser(description="")
    parser.add_argument("-d", "--data_managers_file", required=True, help="The data managers tool .yml file.")
    parser.add_argument("-x", "--shed_data_managers_conf_file", required=True, help="Path to the shed_data_managers_conf.xml file")
    parser.add_argument("-g", "--genome_file", required=True, help="The genome yaml file to read.")
    parser.add_argument("-o", "--outfile", default="dm_genomes.yml", help="The name of the output file to produce.")
    parser.add_argument("--version", action='store_true')
    parser.add_argument("--verbose", action='store_true')

    args = parser.parse_args()

    if args.version:
        print("make_dm_genomes_more_params.py version: %.1f" % VERSION)
        return

    # Set up the output dictionary
    out_conf = {'data_managers': [], 'genomes': []}

    # Read in the data managers file and
    # store the names in a dictionary with
    # the different params
    data_managers_tools = yaml.safe_load(open(args.data_managers_file, 'r'))
    dms = {}
    expected_fields = ['name', 'owner', 'revisions', 'tool_panel_section_label', 'tool_shed_url', 'tags']
    for dm in data_managers_tools['tools']:
        if 'genome' in dm['tags']:
            dms[dm['name']] = {}
            for param in [p for p in dm if p not in expected_fields]:
              dms[dm['name']][param] = dm[param]

    if args.verbose:
        print('Data managers array: %s' % dms)

    # Read in the shed_data_managers_conf.xml file and build a dictionary of name, id and data tables to update and add them to
    # out_conf if they appear in dms
    tree = ET.parse(args.shed_data_managers_conf_file)
    root = tree.getroot()
    for data_manager in root:
        name = ''
        repo = ''
        tables = []
        for tool in data_manager:
            if tool.tag == 'tool':
                for x in tool:
                    if x.tag == 'id':
                        name = x.text
                    elif x.tag == 'repository_name':
                        repo = x.text
            elif tool.tag == 'data_table':
                tables.append(tool.attrib['name'])
        if repo in dms:
            if len(dms[repo]) == 0:
              # There is no specific parameter:
              dm = {}
              dm['id'] = name
              dm['params'] = [{'all_fasta_source': '{{ item.id }}'},{'sequence_name': '{{ item.name }}'},{'sequence_id': '{{ item.id }}'}]
              dm['items'] = '{{ genomes }}'
              dm['data_table_reload'] = tables
              out_conf['data_managers'].append(dm)
            else:
              param_names = list(dms[repo].keys())
              param_values = list(dms[repo].values())
              for new_params in itertools.product(*param_values):
                dm = {}
                dm['id'] = name
                dm['params'] = [{'all_fasta_source': '{{ item.id }}'},{'sequence_name': '{{ item.name }}'},{'sequence_id': '{{ item.id }}'}]
                dm['items'] = '{{ genomes }}'
                dm['data_table_reload'] = deepcopy(tables)
                for i, p_name in enumerate(param_names):
                  dm['params'].append({p_name: new_params[i]})
                out_conf['data_managers'].append(dm)

    #Read in the genome file.
    genomes = yaml.safe_load(open(args.genome_file, 'r'))

    out_conf['genomes'] = genomes['genomes']

    with open(args.outfile, 'w') as out:
        yaml.dump(out_conf, out, default_flow_style=False)

if __name__ == "__main__": main()
