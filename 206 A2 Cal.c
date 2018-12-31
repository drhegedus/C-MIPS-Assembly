#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char * argv[]) {
	
	if (argc != 3) {
		printf("Please enter 2 integers: DAYSIZE and FIRSTDAY. \n");
		return (-1);	
	}

	int DAYSIZE = atoi(argv[1]); 
	int FIRSTDAY = atoi(argv[2]);

	if (DAYSIZE == 0 | FIRSTDAY == 0) {
		printf("The arguments must be integers. \n");
		return (-1);
	}
	
	if (DAYSIZE < 2 | DAYSIZE > 9) {
		printf("ERROR: Cannot print days smaller than size 2 or larger than size 9.\n");
		return (-1);
	} 

	if (FIRSTDAY > 7 | FIRSTDAY < 1) {
		printf("ERROR: The first day of the week must be between 1 and 7.\n");
		return (-1);
	} 
	

	int num_of_chars = (DAYSIZE+3)*(7) + 1;
	int day_for_month = FIRSTDAY - 1;
	char *months[] = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
	char days[7][9] = {"Sunday   ", "Monday   ", "Tuesday  ", "Wednesday", "Thursday ", "Friday   ", "Saturday "};

	for (int month = 0; month < 12; month++) {
		printf("|");
		for (int i = 0; i<num_of_chars - 2; i++){
			printf("-");
		}
		printf("|\n|");


		if (DAYSIZE % 2 == 1) {
			if (strlen(months[month]) % 2 == 0) {
				for (int i = 0; i< (num_of_chars - 2 - strlen(months[month]))/2; i++){
					printf(" ");
				}
				printf("%s", months[month]);
				printf(" ");
				for (int i = 0; i< (num_of_chars - 2 - strlen(months[month]))/2; i++){
					printf(" ");
				}
			} else if (strlen(months[month]) % 2 == 1) {
				for (int i = 0; i< (num_of_chars - 2 - strlen(months[month]))/2; i++){
					printf(" ");
				}
				printf("%s", months[month]);
				for (int i = 0; i< (num_of_chars - 2 - strlen(months[month]))/2; i++){
					printf(" ");
				}
			}	
		} else if (DAYSIZE % 2 == 0){
			if (strlen(months[month]) % 2 == 1) {
				printf(" ");
				for (int i = 0; i< (num_of_chars - 2 - strlen(months[month]))/2; i++){
					printf(" ");
				}
				printf("%s", months[month]);
				for (int i = 0; i< (num_of_chars - 2 - strlen(months[month]))/2; i++){
					printf(" ");
				}
			} else if (strlen(months[month]) % 2 == 0) {
				for (int i = 0; i< (num_of_chars - 2 - strlen(months[month]))/2; i++){
					printf(" ");
				}
				printf("%s", months[month]);
				for (int i = 0; i< (num_of_chars - 1 - strlen(months[month]))/2; i++){
					printf(" ");
				}
			}
		}
		printf("|\n|");


		for (int i = 0; i<num_of_chars - 2; i++){
			printf("-");
		}
		printf("|\n|");

		for (int i = 0; i<7; i++) {
			printf(" ");
			for (int k = 0; k<DAYSIZE ; k++) {
				printf("%c", days[i][k]);
			}
			printf(" |");
		} 
		printf("\n|");

		for (int i = 0; i<num_of_chars - 2; i++){
			printf("-");
		}
		printf("|\n|");

		
		int day_num = 1;

		for (int i = 0; i<day_for_month; i++) {
			for (int s = 0; s < DAYSIZE + 2; s++) {
				printf(" ");
			}
			printf("|");
		}


		for (int i = day_for_month; i<7; i++) {

			printf(" %d", day_num);

			if (DAYSIZE % 2 == 0) {
				if (day_num < 10){
					for (int k = 0; k < DAYSIZE - 1; k++) {
						printf(" ");
					}
				} else {
					for (int k = 0; k < DAYSIZE - 2; k++) {
						printf(" ");
					}
				}	
			} else if (DAYSIZE % 2 == 1) {
				if (day_num < 10){
					for (int k = 0; k < DAYSIZE - 1; k++) {
						printf(" ");
					}
				} else {
					for (int k = 0; k < DAYSIZE - 2; k++) {
						printf(" ");
					}
				}
			}
			printf(" |");			
			day_num++;
			if (i == 6 & day_num != 31) {
				i = -1;
				printf("\n|");
			}
			if (day_num == 31 & i == 6) {
				printf("\n");
				day_for_month = 0;
				break;
			} else if (day_num == 31 & i!= 6) {
				int addOn = 5 - day_for_month;
				day_for_month = 7 - addOn;
				if (addOn == -1) {
					addOn = 6;
					day_for_month = 1;
				}	
				for (int extra = 0; extra < addOn; extra++) {
					for (int s = 0; s < DAYSIZE + 2; s++) {
						printf(" ");
					}
					printf("|");
				}
				printf("\n");
				break;
			}
		}
	}

	printf("|");
	for (int i = 0; i<num_of_chars - 2; i++){
		printf("-");
	}
	printf("|\n");

	
}