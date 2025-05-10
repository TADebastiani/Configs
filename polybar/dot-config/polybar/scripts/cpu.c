#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sensors/sensors.h>
#include <sensors/error.h>

struct stats_cpu {
    unsigned long long cpu_user;
	unsigned long long cpu_nice;
	unsigned long long cpu_sys;
	unsigned long long cpu_idle;
	unsigned long long cpu_iowait;
	unsigned long long cpu_steal;
	unsigned long long cpu_hardirq;
	unsigned long long cpu_softirq;
};

unsigned long long get_stats_cpu(struct stats_cpu **st_cpu) {
    FILE *fp;
    char buffer[8192];
    ssize_t ret;

    fp = fopen("/proc/stat", "r");

    if (fp == NULL) {
        fprintf(stderr, "Failed to open /proc/stat\n");
        perror("fopen");
        exit(EXIT_FAILURE);
    }

    fgets(buffer, sizeof(buffer), fp);

    if (*st_cpu == NULL) {
        *st_cpu = malloc(sizeof(struct stats_cpu));
    }

    memset(*st_cpu, 0, sizeof(struct stats_cpu));

    sscanf(buffer + 5, "%llu %llu %llu %llu %llu %llu %llu %llu",
		   &(*st_cpu)->cpu_user,
		   &(*st_cpu)->cpu_nice,
		   &(*st_cpu)->cpu_sys,
		   &(*st_cpu)->cpu_idle,
		   &(*st_cpu)->cpu_iowait,
		   &(*st_cpu)->cpu_hardirq,
		   &(*st_cpu)->cpu_softirq,
		   &(*st_cpu)->cpu_steal);
    
    fclose(fp);

    return (*st_cpu)->cpu_user +
		   (*st_cpu)->cpu_nice +
		   (*st_cpu)->cpu_sys +
		   (*st_cpu)->cpu_idle +
		   (*st_cpu)->cpu_iowait +
		   (*st_cpu)->cpu_hardirq +
		   (*st_cpu)->cpu_softirq +
		   (*st_cpu)->cpu_steal;
}

double avg(unsigned long long m, unsigned long long n, unsigned long long p) {
    if (n < m) 
        return (double) 0;
    return (((double) n) - ((double) m)) / ((double) p) * 100;
}

int get_usage() {
    struct stats_cpu *st_cpu[2] = {NULL, NULL};
    unsigned long long total[2] = {0, 0};

    total[0] = get_stats_cpu(&st_cpu[0]);

    sleep(1);

    total[1] = get_stats_cpu(&st_cpu[1]);
    
    double idle = avg(st_cpu[0]->cpu_idle, st_cpu[1]->cpu_idle, total[1] - total[0]);

    free(st_cpu[0]);
    free(st_cpu[1]);

    return (int) (100 - idle);
}

void check_sensors_response(int res) {
    if (res != 0) {
        fprintf(stderr, "Failed to load Sensors data\n");
        fprintf(stderr, "\t%s\n", sensors_strerror(res));
        exit(EXIT_FAILURE);
    }
}

void get_value(const sensors_chip_name *chip_name, const sensors_subfeature *subfeat) {
    double value = 0;

    int res = sensors_get_value(chip_name, subfeat->number, &value);
    check_sensors_response(res);
    printf("\t\tvalue: %02.1f\n", value);
}

void list_subfeatures(const sensors_chip_name *chip_name, const sensors_feature *feature) {
    const sensors_subfeature *subfeat;
    int sf = 0;

    while((subfeat = sensors_get_all_subfeatures(chip_name, feature, &sf)) != 0) {
        printf("\tSub-Feature %d: %s (%d)\n", sf, subfeat->name, subfeat->type);
        printf("\t       number: %d\n", subfeat->number);
        printf("\t      mapping: %d\n", subfeat->mapping);
        printf("\t        flags: %0X\n", subfeat->flags);
        get_value(chip_name, subfeat);
    }
}

void list_features(const sensors_chip_name *chip_name) {
    const sensors_feature *feat;
    int f = 0;

    while ((feat = sensors_get_features(chip_name, &f)) != 0) {
        printf("Feature %d: %s (%d)\n", f, feat->name, feat->number);
        list_subfeatures(chip_name, feat);
    }
}

double get_sensors_value(
        const sensors_chip_name *chip_name,
        int feat_nr,
        sensors_subfeature_type subfeat_type
        ) {
    const sensors_feature *feat;
    const sensors_subfeature *subfeat;
    double temperature = 0;

    feat = sensors_get_features(chip_name, &feat_nr);
    if (feat == NULL)
        return temperature;

    subfeat = sensors_get_subfeature(chip_name, feat, subfeat_type);
    if (subfeat == NULL)
        return temperature;

    int res = sensors_get_value(chip_name, subfeat->number, &temperature);
    check_sensors_response(res);
    return temperature;
}

double get_temperature(const char *orig_name) {
    sensors_chip_name search_chip_name;
    const sensors_chip_name *chip_name;
    int res = 0;
    int chip_count = 0;
    double temperature = 0.0;

    res = sensors_init(NULL);
    check_sensors_response(res);

    res = sensors_parse_chip_name(orig_name, &search_chip_name);
    check_sensors_response(res);
    
    chip_name = sensors_get_detected_chips(&search_chip_name, &chip_count);

    temperature = get_sensors_value(chip_name, 0, SENSORS_SUBFEATURE_TEMP_INPUT);

    sensors_free_chip_name(&search_chip_name);

    sensors_cleanup();
    
    return temperature;
}

int main() {
    int usage = get_usage();
    double temp = get_temperature("k10temp-pci-00c3");
    

    printf("%02d%% %2.1f°C\n", usage, temp);
    return 0;
}
