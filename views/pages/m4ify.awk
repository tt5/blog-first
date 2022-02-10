!/^m4/ {
  print "¹"$0"²"
}\
/^m4/ {
  for (i=2; i<NF; i++) printf("%s ", $i);
  printf("%s", $NF); 
  printf("\n")
}
