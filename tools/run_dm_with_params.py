import logging
from jinja2 import Template

from ephemeris import run_data_managers
from ephemeris.run_data_managers import DataManagers, _parser

from ephemeris import get_galaxy_connection
from ephemeris import load_yaml_file
from ephemeris.ephemeris_log import disable_external_library_logging, setup_global_logger


class DataManagersWithParams(DataManagers):
    def update_inputs(self, data_tables, inputs):
        if 'homer_preparse' in data_tables:
            if inputs.get('mask', False):
                mask_suffix = 'r'
            else:
                mask_suffix = ''
            if 'size' not in inputs:
                inputs['size'] = 200
            inputs['value'] = inputs['sequence_id'] + mask_suffix + '_' + str(inputs['size'])


    def get_dm_jobs(self, dm):
        """Gets the job entries for a single dm. Puts entries that already present in skipped_job_list.
        :returns job_list, skipped_job_list"""
        job_list = []
        skipped_job_list = []
        items = self.parse_items(dm.get('items', ['']))
        for item in items:
            dm_id = dm['id']
            params = dm['params']
            inputs = dict()
            # Iterate over all parameters, replace occurences of {{item}} with the current processing item
            # and create the tool_inputs dict for running the data manager job
            for param in params:
                key, value = list(param.items())[0]
                try:
                    value_template = Template(value)
                    value = value_template.render(item=item)
                except TypeError:
                    pass
                inputs.update({key: value})

            data_tables = dm.get('data_table_reload', [])
            self.update_inputs(data_tables, inputs)
            job = dict(tool_id=dm_id, inputs=inputs)

            if self.input_entries_exist_in_data_tables(data_tables, inputs):
                skipped_job_list.append(job)
            else:
                job_list.append(job)
        return job_list, skipped_job_list


def main():
    disable_external_library_logging()
    parser = _parser()
    args = parser.parse_args()
    log = setup_global_logger(name=__name__, log_file=args.log_file)
    if args.verbose:
        log.setLevel(logging.DEBUG)
    else:
        log.setLevel(logging.INFO)
    gi = get_galaxy_connection(args, file=args.config, log=log, login_required=True)
    config = load_yaml_file(args.config)
    data_managers = DataManagersWithParams(gi, config)
    data_managers.run(log, args.ignore_errors, args.overwrite)


if __name__ == '__main__':
    main()
