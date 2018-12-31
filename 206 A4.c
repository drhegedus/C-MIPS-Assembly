#include "A4_sort_helpers.h"
sem_t *sem_array[27];
char sorted[MAX_NUMBER_LINES][MAX_LINE_LENGTH];


// Function: read_all() 
// Provided to read an entire file, line by line.
// No need to change this one.
void read_all( char *filename ){
    
    FILE *fp = fopen( filename, "r" );
    int curr_line = 0;
	
    while( curr_line < MAX_NUMBER_LINES && 
           fgets( text_array[curr_line], MAX_LINE_LENGTH, fp ) )
    {
        curr_line++;
    }
	
    text_array[curr_line][0] = '\0';
    fclose(fp);
}

// Function: read_all() 
// Provided to read only the lines of a file staring with first_letter.
// No need to change this one.
void read_by_letter( char *filename, char first_letter ){

    FILE *fp = fopen( filename, "r" );
    int curr_line = 0;
    text_array[curr_line][0] = '\0';
	
    while( fgets( text_array[curr_line], MAX_LINE_LENGTH, fp ) ){
        if( text_array[curr_line][0] == first_letter ){
            curr_line++;
        }

        if( curr_line == MAX_NUMBER_LINES ){
            sprintf( buf, "ERROR: Attempted to read too many lines from file.\n" );
            write( 1, buf, strlen(buf) );
            break;
        }
    }
	
    text_array[curr_line][0] = '\0';
    fclose(fp);
}




void sort_words( ){
    for (int i = 1; i < MAX_NUMBER_LINES; i++) {
        int j = i;
        
        while (j > 0 && strcmp(text_array[j - 1], text_array[j]) > 0 && text_array[j][0] != '\0') {
            char tmp[MAX_LINE_LENGTH];
            strncpy(tmp, text_array[j - 1], sizeof(text_array[j - 1]));
            strncpy(text_array[j - 1], text_array[j], sizeof(text_array[j - 1]));
            strncpy(text_array[j], tmp, sizeof(tmp));
            j --;
        }
    }
}




int initialize( ){
    sem_unlink("SEM_a");
    sem_array[0] = sem_open("SEM_a", O_CREAT, 0666, 1);
    for (int i = 1; i<26; i++) {
        char str[80];
        sprintf(str, "SEM_%c", 'a' + i);
        sem_unlink(str);
        sem_array[i] = sem_open(str, O_CREAT, 0666, 0);
    }
    sem_array[26] = sem_open("last", O_CREAT, 0666, 0);
    return 0;
}



int process_by_letter( char* input_filename, char first_letter ){
    int position = first_letter - 'a';
    sem_wait(sem_array[position]);
    //sprintf(buf, "This process will sort the letter %c.\n",  first_letter );
    //write(1, buf, strlen(buf));
    read_by_letter( input_filename, first_letter);
    sort_words();
    
    int curr_line = 0;
    while (text_array[curr_line][0] != '\0'){
        sprintf(buf, "%s", text_array[curr_line] );
        write(1, buf, strlen(buf));
        curr_line ++;
    }
    
    if (position < 26) {
        sem_post(sem_array[position + 1]);
    } else if (position == 26) {
        sem_post(sem_array[26]);
    }
    
    return 0;
}




int finalize( ){
    
    sem_wait(sem_array[26]);
    sprintf( buf, "Sorting complete!\n" );
    write( 1, buf, strlen(buf) );
    
    
    return 0;
    
}

