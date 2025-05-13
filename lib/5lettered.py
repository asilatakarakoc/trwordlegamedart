# This script reads TDK_Sözlük_Kelime_Listesi.txt and writes all 5-letter words (uppercase, one per line) to 5-letter-words.txt

input_path = "alltrwords.txt"
output_path = "5-letter-words.txt"

with open(input_path, encoding="utf-8") as infile, open(output_path, "w", encoding="utf-8") as outfile:
    for line in infile:
        word = line.strip()
        # Only accept words that are exactly 5 letters and contain only Turkish letters (no digits, no punctuation)
        if len(word) == 5 and word.isalpha():
            # Do not replace 'i' with 'ı', just use upper()
            for letter in word:
                if letter == 'ı':
                    word = word.replace('ı', 'I')
                if letter == 'i':
                    word = word.replace('i', 'İ')
            outfile.write(word.upper() + "\n")

