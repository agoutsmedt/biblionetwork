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

# adding missing rows

add <- data.frame("ItemID_Ref" = c("1111111190","1111111191","1111111192"),
                  "Author" = c("KLEIN-PA","PARKIN-M","WITTEVEEN-H"),
                  "Year" = c("1978","1980","1975"),
                  "Author_date" = c("KLEIN-P-1978", "PARKIN-M-1980","WITTEVEEN-H-1975"),
                  "Title" = c("STAGFLATION - REPLY", "OIL PUSH INFLATION?", "INFLATION AND THE INTERNATIONAL MONETARY SITUATION"),
                  "Journal" = c("JOURNAL OF ECONOMIC ISSUES", "PSL QUARTERLY REVIEW", "THE AMERICAN ECONOMIC REVIEW"),
                  "Type" = c("Stagflation","Stagflation","Stagflation")
)

Nodes_stagflation <- rbind(Nodes_stagflation, add)

# correcting ID problems

Ref_stagflation[Citing_ItemID_Ref == "111440961"]$Citing_ItemID_Ref = 20533251
Ref_stagflation[Citing_ItemID_Ref == "1111111148"]$Citing_ItemID_Ref = 17355017

# saving in the package
use_data(Nodes_stagflation, overwrite = TRUE)
use_data(Ref_stagflation, overwrite = TRUE)


