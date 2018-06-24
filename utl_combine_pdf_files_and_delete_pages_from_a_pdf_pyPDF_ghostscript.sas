Combine pdf files and delete pages from a pdf. PyPDF and  ghostscript applications.

  SAS and WPS Proc Python

github
https://tinyurl.com/y9lxzz89
https://github.com/rogerjdeangelis/utl_combine_pdf_files_and_delete_pages_from_a_pdf_pyPDF_ghostscript

Need this to handle PDFs
Get ghostscript here (note ghostscript can combine PDF files and can convert PDF to TIF.
http://www.ghostscript.com/download/gsdnld.html
Really only need one executable.
https://www.dropbox.com/s/g153vhv3rgb3ywi/gswin64c.exe?dl=0

Nothing needed for pyPDF2 is in base Python


TWO SOLUTIONS (WPS Proc Python - may not work when deleting scatttered 100s of pages)

     1. Ghostscript
     2. Package pyPDF2 ( provides edit, text extraction and moving pages)


INPUT  (Two psdf files)
=======================

  d:/pdf/iris.pdf  (four pages with page numbering)
  d:/pdf/gnp.pdf  (four pages with page numbering)

  EXAMPLE OUTPUTS (pyPDF2 examples)

  * COMBINE TWO PDFS INTO NEW PDF;

   inp1   = d:/pdf/iris.pdf
   inp2   = d:/pdf/gnp.pdf
   out    = d:/pdf/irisGnpCombine.pdf  (combined)

   d:/pdf/irisGnp.pdf  (with 8 pages)



  * DELETE INDIVIDUAL PAGES  OR UP TO TWO RANGES OF PAGES;

   action = delete 1:2 5:6   * deletes pages;
   action = keep 1:2 5:6     * keeps pages;

   action = delete 1:1 5:5   * delete page 1 and page 5


PROCESS
=======

 1. GHOSTSCRIPT

    Download https://www.dropbox.com/s/g153vhv3rgb3ywi/gswin64c.exe?dl=0
    and place in d:/pdf


    COMBINE PDFs

    %utlfkil(d:/pdf/irisGnpCombineGs.pdf); * just in case it exists;
    x "cd d:/pdf";
    x "gswin64c -dNOPAUSE -sDEVICE=pdfwrite -dQUIET -sOUTPUTFILE=irisGnpCombineGs.pdf -dBATCH gnp.pdf iris.pdf";
    x "cd c:/utl";

    DELETE PAGE 2

    %utlfkil(d:/pdf/irisPage2.pdf);  * just in case it exists;

    x "cd d:/pdf";
    %let lonLyn= %sysfunc(compbl(-sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH
         -dFirstPage=2 -dLastPage=2 -sOutputFile=d:/pdf/irisPage2.pdf d:/pdf/iris.pdf));
    x "gswin64c &lonLyn";
    x "cd c:/utl"; * this is my pwd;

    COMBINE ALL PDS IN A DIRECTORY

    %utlfkil(d:/pdf/irisGnpCombineGs.pdf); * just in case it exists;
    x "cd c:/pdf";
    x 'for %s in (*.pdf) do ECHO %s >> filename.txt';
    x "gswin64c.exe -q -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=all.pdf -dBATCH @filename.txt";
    x "cd c:/utl";


 2. pyPDF

    * keep only pages 2,3,4,6,7,8
    %pypdf(
       inp1  = d:/pdf/irisGnp.pdf
       ,out  = d:/pdf/irisGnpKeep.pdf
       ,action = keep 2:4 6:8
    );


    * delete pages 2,3,4,6,7,8;
    %pypdf(
       inp1  = d:/pdf/irisGnp.pdf
       ,out  = d:/pdf/irisGnpDelete.pdf
       ,action = delete 2:4 6:8
    );

    * delete pages 1,6,8;
    %pypdf(
       inp1  = d:/pdf/irisGnp.pdf
       ,out  = d:/pdf/irisGnpDelete168.pdf
       ,action = delete 1:1 6:6 8:8
    );


    * combine d:/pdf/iris.pdf and d:/pdf/gnp.pdf;
    %pypdf(
       inp1   = d:/pdf/iris.pdf
       ,inp2  = d:/pdf/gnp.pdf
       ,out   = d:/pdf/irisGnpCombine.pdf
    );

*                _             _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

options number;
ods pdf file="d:/pdf/iris.pdf";
proc print data=sashelp.iris;
run;quit;
ods pdf close;

ods pdf file="d:/pdf/gnp.pdf";
proc print data=sashelp.gnp;
run;quit;
ods pdf close;
*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

%macro pypdf(
    inp1    =d:/pdf/irisGnp.pdf
   ,inp2    =N
   ,out     =
   ,action  =
   ) / des="combine or remove pages from a pdfs";

   %if "&inp2" eq "N" %then %do;
       data _null_;
          length action rng $512;
          retain action "&action" ;
          act=substr(action,anydigit(action));
          do i=1 to countw(compbl(act),' ');
             actcut=scan(act,i,' ');
             do j=input(scan(actcut,1,':'),3.) to input(scan(actcut,2,':'),3.);
                rng=catx(',',rng,put(j-1,3.));
             end;
          end;
          put rng=;
          call symputx('rng',rng);
          if scan(upcase(left(action)),1,' ')="DELETE" then call symputx("logi","not");
          else call symputx("logi","  ");
          stop;
       run;quit;

       * in works;
       %utl_submit_wps64("
       options set=PYTHONHOME 'C:\Progra~1\Python~1.5\';
       options set=PYTHONPATH 'C:\Progra~1\Python~1.5\\lib\';
       libname sd1 'd:/sd1';
       proc python;
       submit;
       import itertools;
       from PyPDF2 import PdfFileWriter, PdfFileReader, PageRange;
       pages_to_keep = [&rng.];
       infile = PdfFileReader('d:/pdf/irisGnp.pdf', 'rb');
       output = PdfFileWriter();
       for i in range(infile.getNumPages()):;
       .   if i &logi in pages_to_keep:;
       .       p = infile.getPage(i);
       .       output.addPage(p);
       with open('&out', 'wb') as f:;
       .   output.write(f);
       endsubmit;
       run;quit;
       ");

   %end;
   %else %do;
       %utl_submit_wps64("
       options set=PYTHONHOME 'C:\Progra~1\Python~1.5\';
       options set=PYTHONPATH 'C:\Progra~1\Python~1.5\\lib\';
       libname sd1 'd:/sd1';
       proc python;
       submit;
       import PyPDF2;
       pdf1File = open('&inp1.', 'rb');
       pdf2File = open('&inp2', 'rb');
       pdf1Reader = PyPDF2.PdfFileReader(pdf1File);
       pdf2Reader = PyPDF2.PdfFileReader(pdf2File);
       pdfWriter = PyPDF2.PdfFileWriter();
       for pageNum in range(pdf1Reader.numPages):;
       .    pageObj = pdf1Reader.getPage(pageNum);
       .    pdfWriter.addPage(pageObj);
       for pageNum in range(pdf2Reader.numPages):;
       .    pageObj = pdf2Reader.getPage(pageNum);
       .    pdfWriter.addPage(pageObj);
       pdfOutputFile = open('&out', 'wb');
       pdfWriter.write(pdfOutputFile);
       pdfOutputFile.close();
       pdf1File.close();
       pdf2File.close();
       endsubmit;
       run;quit;
       ");
   %end;

%mend pypdf;

* pyPDF;

%utlfkil(d:/pdf/irisGnpKeep.pdf);     * for development;
%symdel inp1 inp2 out action /nowarn; * for development;

%pypdf(
   inp1  = d:/pdf/irisGnp.pdf
   ,out  = d:/pdf/irisGnpKeep.pdf
   ,action = keep 1:2 6:8
);


%utlfkil(d:/pdf/irisGnpDelete.pdf);
%symdel inp1 inp2 out action /nowarn;
%pypdf(
   inp1  = d:/pdf/irisGnp.pdf
   ,out  = d:/pdf/irisGnpDelete.pdf
   ,action = delete 1:2 6:7
);


%utlfkil(d:/pdf/irisGnpCombine.pdf);
%symdel inp1 inp2 out action /nowarn;
%pypdf(
   inp1   = d:/pdf/iris.pdf
   ,inp2  = d:/pdf/gnp.pdf
   ,out   = d:/pdf/irisGnpCombine.pdf
);


* GHOSTSCRIPT;

%utlfkil(d:/pdf/irisGnpCombineGs.pdf); * just in case it exists;
x "cd d:/pdf";
x "gswin64c -dNOPAUSE -sDEVICE=pdfwrite -dQUIET -sOUTPUTFILE=irisGnpCombineGs.pdf -dBATCH gnp.pdf iris.pdf";
x "cd c:/utl";

DELETE PAGE 2

%utlfkil(d:/pdf/irisPage2.pdf);  * just in case it exists;

x "cd d:/pdf";
%let lonLyn= %sysfunc(compbl(-sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH
     -dFirstPage=2 -dLastPage=2 -sOutputFile=d:/pdf/irisPage2.pdf d:/pdf/iris.pdf));
x "gswin64c &lonLyn";
x "cd c:/utl"; * this is my pwd;

COMBINE ALL PDS IN A DIRECTORY

%utlfkil(d:/pdf/irisGnpCombineGs.pdf); * just in case it exists;
x "cd c:/pdf";
x 'for %s in (*.pdf) do ECHO %s >> filename.txt';
x "gswin64c.exe -q -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=all.pdf -dBATCH @filename.txt";
x "cd c:/utl";


*                    __   _  _
__      ___ __  ___ / /_ | || |
\ \ /\ / / '_ \/ __| '_ \| || |_
 \ V  V /| |_) \__ \ (_) |__   _|
  \_/\_/ | .__/|___/\___/   |_|
         |_|
;


 %macro utl_submit_wps64(pgmx,resolve=Y)/des="submiit a single quoted sas program to wps";
  * write the program to a temporary file;

/*
  %utlfkil(%sysfunc(pathname(work))/wps_pgmtmp.wps);
  %utlfkil(%sysfunc(pathname(work))/wps_pgm.wps);
  %utlfkil(%sysfunc(pathname(work))/wps_pgm001.wps);
  %utlfkil(wps_pgm.lst);
  %utlfkil(sysfunc(pathname(work))/wps_pgm.wps);
 */

  filename wps_pgm "%sysfunc(pathname(work))/wps_pgmtmp.wps" lrecl=32756 recfm=v;

  data _null_;
    length pgm  $32756 cmd $32756;
    file wps_pgm ;
    %if %upcase(%substr(&resolve,1,1))=Y %then %do;
       pgm=resolve(&pgmx);
    %end;
    %else %do;
      pgm=&pgmx;
    %end;
    semi=countc(pgm,';');
      do idx=1 to semi;
        cmd=cats(scan(pgm,idx,';'),';');
        len=length(strip(cmd));
        put cmd $varying32756. len;
        putlog cmd $varying32756. len;
      end;
  run;

  filename wps_001 "%sysfunc(pathname(work))/wps_pgm001.wps" lrecl=255 recfm=v ;
  data _null_ ;
    length textin $ 32767 textout $ 255 ;
    file wps_001;
    infile "%sysfunc(pathname(work))/wps_pgmtmp.wps" lrecl=32767 truncover;
    format textin $char32767.;
    input textin $char32767.;
    putlog _infile_;
    if lengthn( textin ) <= 255 then put textin ;
    else do while( lengthn( textin ) > 255 ) ;
       textout = reverse( substr( textin, 1, 255 )) ;
       ndx = index( textout, ' ' ) ;
       if ndx then do ;
          textout = reverse( substr( textout, ndx + 1 )) ;
          put textout $char255. ;
          textin = substr( textin, 255 - ndx + 1 ) ;
    end ;
    else do;
      textout = substr(textin,1,255);
      put textout $char255. ;
      textin = substr(textin,255+1);
    end;
    if lengthn( textin ) le 255 then put textin $char255. ;
    end ;
  run ;

  %put ****** file %sysfunc(pathname(work))/wps_pgm.wps ****;

  filename wps_fin "%sysfunc(pathname(work))/wps_pgm.wps" lrecl=255 recfm=v ;
  data _null_;
      retain switch 0;
      infile wps_001;
      input;
      file wps_fin;
      if substr(_infile_,1,1) = '.' then  _infile_= substr(left(_infile_),2);
      select;
         when(left(upcase(_infile_))=:'SUBMIT;')     switch=1;
         when(left(upcase(_infile_))=:'ENDSUBMIT;')  switch=0;
         otherwise;
      end;
      if lag(switch)=1 then  _infile_=compress(_infile_,';');
      if left(upcase(_infile_))= 'ENDSUBMIT' then _infile_=cats(_infile_,';');
      put _infile_;
      putlog _infile_;
  run;quit;

  %let _loc=%sysfunc(pathname(wps_fin));
  %let _w=%sysfunc(compbl(C:/Progra~1/worldp~1/bin/wps.exe -autoexec c:\oto\Tut_Otowps.sas -config c:\cfg\wps.cfg));
  %put &_loc;

  filename rut pipe "&_w -sysin &_loc";
  data _null_;
    file print;
    infile rut;
    input;
    put _infile_;
    putlog _infile_;
  run;


  filename rut clear;
  filename wps_pgm clear;
  data _null_;
    infile "wps_pgm.lst";
    input;
    putlog _infile_;
  run;quit;


%mend utl_submit_wps64;

