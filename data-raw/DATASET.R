## code to prepare `DATASET` dataset goes here

library(data.table)
Nodes_stagflation <- as.data.table(Nodes_stagflation)
Nodes_stagflation <- Nodes_stagflation[, `:=` (Title = toupper(Title), Journal = toupper(Journal))]

Ref_stagflation <- as.data.table(Ref_stagflation)
Ref_stagflation <- Ref_stagflation[, `:=` (Title = toupper(Title), Author = toupper(Author), Journal = toupper(Journal))]

library(stringr)
Nodes_stagflation$Title <- str_replace_all(Nodes_stagflation$Title, "<96>","-")
Nodes_stagflation$Title <- str_replace_all(Nodes_stagflation$Title, "<e2><80><93>","-")
Nodes_stagflation$Title <- str_replace_all(Nodes_stagflation$Title, "<e2><88><92>","-")
Nodes_stagflation$Title <- str_replace_all(Nodes_stagflation$Title, "<e2><80><94>","-")
Nodes_stagflation$Title <- str_replace_all(Nodes_stagflation$Title, "<e2><80><98>","-")
Nodes_stagflation$Title <- str_replace_all(Nodes_stagflation$Title, "<e2><80><94>","-")

Ref_stagflation$Author <- str_replace_all(Ref_stagflation$Author, "<c3><ad>","I")
Ref_stagflation$Author <- str_replace_all(Ref_stagflation$Author, "<c3><ae>","I")
Ref_stagflation$Author <- str_replace_all(Ref_stagflation$Author, "<c4><b1><c2><b4>","I")
Ref_stagflation$Author <- str_replace_all(Ref_stagflation$Author, "<c3><a7>","C")
Ref_stagflation$Author <- str_replace_all(Ref_stagflation$Author, "<96>","-")
Ref_stagflation$Author <- str_replace_all(Ref_stagflation$Author, "<96>","-")
Ref_stagflation$Author <- str_replace_all(Ref_stagflation$Author, "<96>","-")

Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<96>","-")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<e2><80><93>","-")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<e2><88><92>","-")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<e2><80><94>","-")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<e2><80><98>","-")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<e2><80><94>","-")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<c2><ae>","FF")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<c3><87>","C")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<e2><80><9c>","'")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<e2><80><9d>","'")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<c2><80><8c>","'")
Ref_stagflation$Title <- str_replace_all(Ref_stagflation$Title, "<c2><80><9d>","'")

Ref_stagflation$Journal <- str_replace_all(Ref_stagflation$Journal, "<c2><80><8c>MEASURING MONETARY POLICY<c2><80><9d>","")
Ref_stagflation$Journal <- str_replace_all(Ref_stagflation$Journal, "EVIDENCE AND SOME THEORY<c2><80><9d>","")
Ref_stagflation$Journal <- str_replace_all(Ref_stagflation$Journal, "EVIDENCE AND SOME THEORYÂ€\u009d ","")
Ref_stagflation$Journal <- str_replace_all(Ref_stagflation$Journal, "Â€ŒMEASURING MONETARY POLICYÂ€\u009d ","")

# saving in the package
use_data(Nodes_stagflation, overwrite = TRUE)
use_data(Ref_stagflation, overwrite = TRUE)
