system("mkdir -p tmp out");
$aux_dir = 'tmp';
$out_dir = 'out'; # Joga o PDF para o dir out

$pdf_mode = 1;  # pdflatex
$synctex = 1; # Geera essa merda de Syntec na tmp

$clean_ext = 'synctex.gz synctex.gz(busy) run.xml';

# At program exit, move any PDFs produced in tmp to out (silently ignore if none)
END {
	system("mkdir -p out");
	system("cp tmp/*.pdf out/ 2>/dev/null || true");
}
