#include <stdio.h>
#include <unistd.h>
#include "data.h"
#include "mtb_str.h"

char *rsync_src_dst_string(char *profile_name, Element *e, Target *t) {
	char *str = mtbs_join(2, e->source, " ");

	if(t->address)
		mtbs_concat(9, &str, t->user, "@", t->address, ":", t->path, profile_name, "/", e->destination);
	else
		mtbs_concat(6, &str, " ", t->path, profile_name, "/", e->destination);

	return str;
}

void sync_profile_to_target(Profile *profile, Target *target) {
	char *cmd_base = mtbs_new("rsync -azhvP ");
	char *dirs, *cmd;

	for(int i = 0; i < profile->n_elements; i++) {
		dirs = rsync_src_dst_string(profile->name, (profile->element) + i, target);
		cmd = mtbs_join(2, cmd_base, dirs);

		printf("\nRunning %s\n", cmd);
		system(cmd);

		free(cmd);
		free(dirs);
	}
	free(cmd_base);
	return;
}
