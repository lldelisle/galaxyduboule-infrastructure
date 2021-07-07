from bioblend.galaxy import GalaxyInstance
import sys
import time

gi = GalaxyInstance('https://galaxyduboule.epfl.ch', key=sys.argv[1])
installed_tools = [d for d in gi.toolshed.get_repositories() if d['status'] == "Installed"]
for my_tool in installed_tools:
    print(my_tool)
    try:
      gi.toolshed.uninstall_repository_revision(name=my_tool['name'], owner=my_tool['owner'],
                                                changeset_revision=my_tool['changeset_revision'],
                                                tool_shed_url=my_tool['tool_shed'])
    except Exception as e:
      print("FAILED")
      print(e)
