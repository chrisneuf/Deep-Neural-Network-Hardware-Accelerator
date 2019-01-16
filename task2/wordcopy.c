

#define wordcpy_acc (volatile unsigned *) 0x00001040 /* memory copy accelerator */
#define source (volatile unsigned *) 0x0a004000
#define dest (volatile unsigned *) 0x0a004020

/* use our memcpy accelerator; pointers must be word-aligned */
void wordcpy(int *dst, int *src, int n_words) {
    *(wordcpy_acc + 1) = (unsigned) dst;
    *(wordcpy_acc + 2) = (unsigned) src;
    *(wordcpy_acc + 3) = (unsigned) n_words;
    *wordcpy_acc = 0; /* start */
    *wordcpy_acc; /* make sure the accelerator is finished */
}

void main() {

    *(source) = (int) 10;
    *(source + 1) = (int) 11;
    *(source + 2) = (int) 12;
    *(source + 3) = (int) 13;
    *(source + 4) = (int) 0xDEADBEEF;

    wordcpy((int *)dest, (int *)source, 5);

    return;
}
