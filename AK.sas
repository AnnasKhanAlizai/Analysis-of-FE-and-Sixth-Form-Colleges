/*********************************************************************************/
/*                                                                               */
/*	Learner: Annas Khan Alizai								    	Date: 26/2/25*/
/*	Title:   Data Programming Analytics Assignment   	 	     Version: Final  */
/*	Email:   akalizai786@gmail.com  			      	    	                 */
/*                                                                               */
/*********************************************************************************/

/***************************************************************************************************/
/*                                                                                                 */
/* ===> Working layout is inspired by Respected Prof. Dr Anthony Williams lab sas worksheets <===  */
/*                                                                                                 */
/*  Declaration references:                                                                        */
/*  Respected Prof. Dr Anthony Williams Lecture PPTs                                               */
/*  Helping material provided by respected professor Williams Anthony                              */
/*  SAS online help                                                                                */
/*  Github examples                                                                                */
/*  Step-by-Step Programming book                                                                  */
/*  This worksheet layout and working idea is inspired from all the labs worksheets specially      */
/*  Lab1 Task(1,5,7,9,10,14,15) Lab2 Task(1,2,8,16) Lab3 Task(1,2,7,9,10,11,12,13) Lab4 Task(1,3)  */
/*  Lab5 Task(2,4,5,6,7) Lab6 Task(1,4) Lab7 Task(1,3,4,5,6) Lab 9 Task (11) and                   */
/*  Lab 10 Task(1,2,3,4,6,7)                                                                       */
/*                                                                                                 */
/***************************************************************************************************/


/***********************************************************************************************/
/*                                                                                             */
/* STEP 1: Defining the library                                                                */
/* Ref: Lecture slides, Lab 4 Sessions and Chapter 35 Understanding SAS Libraries, pp. 715–722 */
/*                                                                                             */
/***********************************************************************************************/

libname worklib '/home/u64277305/Assignment Try';


/***********************************************************************/
/*                                                                     */
/* STEP 2: Reading FE CSV dataset                                      */
/* Ref: Chapter 3 Introduction to DATA Step Processing, pp. 25–47      */
/*      Chapter 4 Starting with Raw Data: The Basics, pp. 52–70        */
/*      Lecture and Lab Sessions                                       */
/*      Lecture and Lab 4 Sessions                                     */
/***********************************************************************/

filename FE '/home/u64277293/sasuser.v94/Assignment';


data fe_raw;
  infile "/home/u64277293/sasuser.v94/Assignment/CSIP5302-FE.csv"
         dsd dlm=',' firstobs=2 truncover;
  /* DSD handles delimited data=> TRUNCOVER prevents line overflow
     Ref: Chapter 4, pp. 55–56 and pp. 86–88 
     Line of code inspired from lab worksheet*/

  length ID 8 College $40 Region $30;
  /* Explicit variable attributes
     Ref: Chapter 3, pp. 40–41 
     Line of code inspired from lab worksheet*/

  input
    ID
    College :$40.
    Region  :$30.
    TotalCH_Y1
    Learners_Y1
    TotalCH_Y2
    Learners_Y2
    TotalCH_Y3
    Learners_Y3
    GPercentMale;
run;

title'Original FE raw data';
proc print
data=fe_raw;
run;
title;

/**********************************************************************/
/*                                                                    */
/* STEP 3: Remove aggregate subtotal rows and log anomalies           */
/* Ref: Chapter 10 Acting on Selected Observations, pp. 153–173       */
/*      Chapter 11 Creating Subsets of Observations, pp. 175–188      */
/*      Chapter 7  p.117                                              */
/*      week 4 lab7                                                   */
/*                                                                    */
/**********************************************************************/
data fe_clean fe_anom;
  set fe_raw;
  length Check $80 InstType $12;
  InstType = "FE";

  /* IF logic to detect and remove aggregate rows
     Ref: Chapter 10, pp. 160–168 and Chapter 7, p.117*/
  if missing(ID) then do;
    Check = "Aggregate row (subtotal/total)";
    output fe_anom;
    delete;  
  end;

  output fe_clean;
run;

title'FE Clean';
proc print
data=fe_clean;
run;
title;

title'FE Anomalies';
proc print
data=fe_anom;
run;
title;

/***********************************************************************/
/*                                                                     */
/* STEP 4: Reading FE metric file                                      */
/* Ref: Chapter 3, pp. 45–47                                           */
/*                                                                     */
/***********************************************************************/
data fe_metric;
  infile "/home/u64277293/sasuser.v94/Assignment/CSIP5302-FEmetric03.tab"
         dlm='09'x firstobs=2 truncover;
  input ID AVPR3 VAF3;
run;

Title 'FE Metric';
proc print
data=fe_metric;
run;
title;

/**************************************************************************************/
/*                                                                                    */
/*Step 5: Check Missing values (How to check missing values learn from lab sessions)  */
/*                                                                                    */
/**************************************************************************************/

title 'Checking The Missing Metrics Counts';
proc means data=fe_metric n nmiss;
    var AVPR3 VAF3;
run;
title;

/***********************************************************************/
/*                                                                     */
/* STEP 6: Sort datasets before merging                                */
/* Ref: Chapter 19 – Merging SAS Data Sets, pp. 299–308                */
/*                                                                     */
/***********************************************************************/
proc sort data=fe_clean;  by ID; run;
proc sort data=fe_metric; by ID; run;


/*****************************************************************************/
/*                                                                           */
/* STEP 7: Match merging FE dataset with matrics using ID                    */
/* Ref: Chapter 19 Match Merging, pp. 308–323, Lecture 3A, and Lab Session.  */
/*      Lecture and Lab Sessions                                             */
/*                                                                           */
/*****************************************************************************/

data fe_final_mrg;
  merge fe_clean(in=a) fe_metric(in=b);
  by ID;

  if a;  /* Keeping FE records only */

  /* Creating a new variables
     Ref: Chapter 3, pp. 32–35 */
  GradPR = AVPR3;/* we converted bcz 6th form CSV contains same column names */
  VAF    = VAF3;

  /* Deriving the female percentage*/
  GPercentFemale = 100 - GPercentMale;   /* did this because 6th form CSV contain GPercentFemale*/
run;

title 'FE Final Mrg';
proc print
data=fe_final_mrg;
run;
title;

/**************************************************************************************/
/*                                                                                    */
/*Step 8: Check Missing values (How to check missing values learn from lab sessions)  */
/*                                                                                    */
/**************************************************************************************/

title "Checking The Missing Metrics Counts";
proc means data=fe_final_mrg n nmiss;
    var GradPR VAF;
run;

/*******************************************************************************************************/
/* Step 9:                                                                                              */
/* we kicked out the the null values which are in FE Metric including their corresponding               */
/* FE college CSV file values because after merging when we analyzed we seen we have 12 missing         */
/* values in a single rows which I think is not appropriate so i prefered to not go with these two rows */
/*                                                                                                      */
/********************************************************************************************************/

data fe_final_merge fe_anom_merge;
  set fe_final_mrg;
  length Check $80 InstType $12;
  InstType = "FE";

  /* Detecting and removing rows where VAF is missing */
  if missing(vaf) then do;
    Check = "Missing VAF value";
    output fe_anom_merge;
    delete;
  end;

  /* All remaining rows are clean */
  output fe_final_merge;
run;

title 'FE Final Merge';
proc print
data=fe_final_merge;
run;
title;

title 'FE Anomalies Merge';
proc print
data=fe_anom_merge;
run;
title;

/*************************************************************************************************************************************/
/* Step 10:                                                                                                                          */
/*Check Missing values (How to check missing values learned from lab sessions)                                                       */
/*Now you can see after running this code we do not get missing values in GradPR VAF correspondings now our dataset contains         */
/*almost 4% missing values which is not much significant, we can also clean it by deleting those rows or by inserting backward fill, */
/*forward fill or meadian, mean or mode value. but we will go with 4% now.                                                           */
/*                                                                                                                                   */
/*************************************************************************************************************************************/

title "Checking The FE Final Merge Sample";
proc print data=fe_final (obs=5); 
run;

title "Checkinf The Missing Metrics Counts";
proc means data=fe_final_merge n nmiss;
    var GradPR VAF GPercentMale TotalCH_Y1 Learners_Y1 TotalCH_Y2 Learners_Y2 TotalCH_Y3 Learners_Y3;
run;


/***********************************************************************/
/*                                                                     */
/* STEP 11: Reading sixth form CSV dataset                              */
/* Ref: Chapter 3 Introduction to DATA Step Processing, pp. 25–47      */
/*      Chapter 4 Starting with Raw Data: The Basics, pp. 52–70        */
/*      Lecture and Lab Sessions                                       */
/*      Lecture and Lab 4 Sessions                                     */
/*                                                                     */
/***********************************************************************/

data six_raw;
  infile "/home/u64277293/sasuser.v94/Assignment/CSIP5302-6form.csv"
         dsd dlm=',' firstobs=2 truncover;

  length College $40 Region $30 InstType $12;
  

  input
    TotalCH_Y1
    Learners_Y1
    TotalCH_Y2
    Learners_Y2
    TotalCH_Y3
    Learners_Y3
    GradPR
    VAF
    College :$40.
    Region  :$30.
    GPercentFemale;
    

  GPercentMale = 100 - GPercentFemale;
run;

title 'Six Form Raw Original Data View';
proc print
data=six_raw;
run;
title;
/************************************************************************/
/*                                                                      */
/* STEP 12: Remove aggregate (subtotal / total) rows and log anomalies */
/* Ref: Chapter 10 Acting on Selected Observations, pp. 153–173         */
/*      Chapter 11 Creating Subsets of Observations, pp. 175–188        */
/*      Chapter 7  p.117                                                */
/*                                                                      */
/************************************************************************/

data six_clean six_anom;
  set six_raw;
  length Check $80 InstType $12;
  InstType = "SF";

  /* IF logic to detect and remove aggregate rows
     Ref: Chapter 10, pp. 160–168 and Chapter 7, p.117*/
  if missing(GPercentFemale) then do;
    Check = "Aggregate row (subtotal/total)";
    output six_anom;
    delete;  
  end;

  output six_clean;
run;

title'Six Form Clean Data';
proc print
data=six_clean;
run;
title;


/*******************************************************/
/*This is what we have anomolies in Sixth form dataset */
/*******************************************************/

title'Six Form Anomalies Set';
proc print
data=six_anom;
run;
title;


/***************************************************************************************/
/* Note:                                                                               */
/*           I am facing the difficulty for my further analysis because i am           */
/*           strulling to get the output of Avglearners and AvgCHPL=>                  */
/* Solution=> to over come this issue I rearranged the column names according to the   */
/*           FE college file column names below                                        */
/***************************************************************************************/

data six_clean_reordered;
  retain 
    College 
    Region
    TotalCH_Y1
    Learners_Y1
    TotalCH_Y2
    Learners_Y2
    TotalCH_Y3
    Learners_Y3
    GradPR
    VAF
    GPercentFemale
    GPercentMale;
    
  set six_clean;

run;

title 'Sixth Form Cleaned Reordered Alligned Dataset';
proc print
data=six_clean_reordered;
run;
title;
/********************************************************/
/* Mean among the variables Ref Chapter 13 page 207–212 */
/********************************************************/

data six_final;
  set six_clean_reordered;

  /* Conditional logic avoids division by zero
     Ref: Chapter 10, pp. 160–168 */
  if Learners_Y1 > 0 then CHPL_Y1 = TotalCH_Y1 / Learners_Y1;
  if Learners_Y2 > 0 then CHPL_Y2 = TotalCH_Y2 / Learners_Y2;
  if Learners_Y3 > 0 then CHPL_Y3 = TotalCH_Y3 / Learners_Y3;

  AvgLearners = mean(of Learners_Y1 Learners_Y2 Learners_Y3);
  AvgCHPL     = mean(of CHPL_Y1 CHPL_Y2 CHPL_Y3);
run;

title 'Six form Final Dataset output';
proc print
data=six_final;
run;
title;
/***********************************************************************/
/* STEP 9: Creating the derived variables (CH per learner and averages)*/
/* Ref: Chapter 8 Working with Numeric Variables, pp. 124–130          */
/*      Lecture and Lab Sessions                                       */
/***********************************************************************/

data fe_final;
  set fe_final_merge;
  
  
  /* I am going to drop two columns AVPR2 and VAF3 because of dublication   */
  drop AVPR3 VAF3;
  
  /* Conditional logic avoids division by zero*/
  if Learners_Y1 > 0 then CHPL_Y1 = TotalCH_Y1 / Learners_Y1;
  if Learners_Y2 > 0 then CHPL_Y2 = TotalCH_Y2 / Learners_Y2;
  if Learners_Y3 > 0 then CHPL_Y3 = TotalCH_Y3 / Learners_Y3;

  AvgLearners = mean(of Learners_Y1 Learners_Y2 Learners_Y3);
  AvgCHPL     = mean(of CHPL_Y1 CHPL_Y2 CHPL_Y3);
run;

title'FE Final DataSet After Removing Dublicate Rows';
proc print
data=fe_final;
run;
Title;


/**********************************************************************************************/
/*                                                                                            */
/* Note:                                                                                      */
/* we can do previous two code in just one time after merging result output will be the       */
/*same but i did separetly                                                                    */ 
/*                                                                                            */
/**********************************************************************************************/

/*************************************************************************************************/
/*                                                                                               */
/* STEP 8: Combining the FE and Sixth Form datasets                                              */
/* Ref: Lecture week 3 and Lab week 3, Chapter 16 methods of combining SAS Data Sets, pp. 257–263*/
/*                                                                                               */
/*************************************************************************************************/

data compiled_wide;
  set fe_final six_final;
run;

Title'Compile Wide DataSet Output';
proc print
data=compiled_wide;
run;
Title;

/*********************************************************/
/* Let us see the contents of the dataset compiled wide  */
/*********************************************************/

Title'Compile Wide DataSet Contents';
proc contents data=compiled_wide;
run;
title;

/*************************************************************************/
/* Checking Skewness of every variable in compiled_wide dataset          */
/* Code is inspired from the Professor Anthony Williams lab worksheets   */
/*************************************************************************/

proc univariate data=compiled_wide;
 var TotalCH_Y1 Learners_Y1 TotalCH_Y2	Learners_Y2	TotalCH_Y3	Learners_Y3	GPercentMale GradPR	VAF AvgCHPL AvgLearners	GPercentFemale	CHPL_Y1	CHPL_Y2	CHPL_Y3;
  ppplot / normal(mu= est sigma= est);
  qqplot / normal(mu=est sigma=est);
  inset n nmiss min q1 median q3 max skew kurt / position= SE ;
run;

/*****************************************************************************/
/*Comment:                                                                   */
/*We analyzed that Skewness exist in our dataset                             */
/*According to the Lecture instruction we do not need to                     */
/*apply transformation but I applied just to get familiar with its working.  */
/* I will not include this in report analysis.                               */
/*****************************************************************************/

/***********************************************************************/
/* STEP 9: Create size categories (min ≤ x < max)                      */
/* Ref: Chapter 8 Numeric comparisons, pp. 128–130                     */
/* converting cutpoints into macros lecture and lab worksheet 10       */               
/***********************************************************************/

proc univariate 
  data=compiled_wide noprint;
  var AvgCHPL;
  output out=cutpoints 
  pctlpts=20 40 60 80
  pctlpre=c
  pctlname=p20 p40 p60 p80;
run;

data _null_;
set cutpoints;
call symputx ('cp20',cp20);
call symputx ('cp40',cp40);
call symputx ('cp60',cp60);
call symputx ('cp80',cp80);
run;

data compiled_wide;
  set compiled_wide;
  length SizeCat $12;

  if AvgCHPL <  &cp20 then SizeCat="Small";
  else if AvgCHPL >= &cp20 and AvgCHPL < &cp40 then SizeCat="Small-Medium";
  else if AvgCHPL >= &cp40 and AvgCHPL < &cp60 then SizeCat="Medium";
  else if AvgCHPL >= &cp60 and AvgCHPL < &cp80 then SizeCat="Large-Medium";
  else if AvgCHPL >= &cp80 then SizeCat="Large";
run;

/*---------------------------------------------------------------------------------------*/
/*
data compiled_wide;
  set compiled_wide;
  length SizeCat $12;

  if AvgLearners <  150.297 then SizeCat="Small";
  else if AvgLearners >= 150.297 and AvgLearners < 187.375 then SizeCat="Medium";
  else if AvgLearners >= 187.375 and AvgLearners < 233.965 then SizeCat="MediumPlus";
  else if AvgLearners >= 233.965 and AvgLearners < 467.295 then SizeCat="Large";
  else if AvgLearners >= 12862.17 then SizeCat="LargePlus";
run;
*/
/*--------------------------------------------------------------------------------------*/

Title 'Size Categories Metric For Sixth Form Colleges';
proc print
data=compiled_wide (obs=10);
run;


/***************************************************************************************/
/*                                                                                     */
/*                  Below Code resuts are not included in Report Writing               */
/*                                                                                     */
/***************************************************************************************/


/***************************************************************************************/
/*                                                                                     */
/* STEP 9: Create size categories (min ≤ x < max)                                      */
/* Ref: Chapter 8 Numeric comparisons, pp. 128–130                                     */
/* converting cutpoints into macros lecture and lab worksheet 10                       */
/*                                                                                     */               
/***************************************************************************************/
/*-------------------------------------------------------------------------------------*/
proc univariate 
  data=compiled_wide noprint;
  var AvgLearners;
  output out=cutpoints 
  pctlpts=20 40 60 80
  pctlpre=c
  pctlname=p20 p40 p60 p80;
run;

data _null_;
set cutpoints;
call symputx ('cp20',cp20);
call symputx ('cp40',cp40);
call symputx ('cp60',cp60);
call symputx ('cp80',cp80);
run;

data compiled_wide;
  set compiled_wide;
  length SizeCat $12;

  if AvgLearners <  &cp20 then SizeCat="Small";
  else if AvgLearners >= &cp20 and AvgLearners < &cp40 then SizeCat="Small-Medium";
  else if AvgLearners >= &cp40 and AvgLearners < &cp60 then SizeCat="Medium";
  else if AvgLearners >= &cp60 and AvgLearners < &cp80 then SizeCat="Large-Medium";
  else if AvgLearners >= &cp80 then SizeCat="Large";
run;

/*
data compiled_wide;
  set compiled_wide;
  length SizeCat $12;

  if AvgLearners <  2362.5 then SizeCat="Small";
  else if AvgLearners >= 2362.5 and AvgLearners < 5997 then SizeCat="Medium";
  else if AvgLearners >= 5997 and AvgLearners < 8907.83 then SizeCat="MediumPlus";
  else if AvgLearners >= 8907.83 and AvgLearners < 12862.167 then SizeCat="Large";
  else if AvgLearners >= 12862.17 then SizeCat="LargePlus";
run;
*/
Title 'Size Categories For FE Colleges';
proc print
data=compiled_wide (obs=10);
run;


/******************************************************************************************************/
/*                                                                                                    */
/* Final extracted required categorey ranges for size of institution table in terms of CH per learner */
/*                                                                                                    */
/******************************************************************************************************/

data cat_tab1;
set compiled_wide;
keep College Region Learners_Y1 Learners_Y2 Learners_Y3 AvgLearners SizeCat;
run;

proc print
data = cat_tab1;
run;
/*----------------------------------------------------------------------------------------*/


/******************************************************************************************************/
/*                                                                                                    */
/* Final extracted required categorey ranges for size of institution table in terms of CH per learner */
/*                                                                                                    */
/******************************************************************************************************/

data cat_tab;
set compiled_wide;
keep College Region CHPL_Y1 CHPL_Y2 CHPL_Y3 AvgCHPL SizeCat;
run;

proc print
data = cat_tab;
run;

/******************************************************************************************************************/
/* STEP 10: Taking the Transpose of data reshaping data from wide to long                                         */
/* Ref: Lab week3, SAS Step by Step book, SAS help example, Chapter 5 – Creating Multiple Observations, pp. 74–78 */
/* working idea got from github example                                                                           */
/******************************************************************************************************************/

data compiled_long;
  set compiled_wide;

  array tch[3] TotalCH_Y1 TotalCH_Y2 TotalCH_Y3;
  array lrn[3] Learners_Y1 Learners_Y2 Learners_Y3;
  array chp[3] CHPL_Y1 CHPL_Y2 CHPL_Y3;

  do Year = 1 to 3;
    TotalCH = tch[Year];
    Learners = lrn[Year];
    CH_per_Learner = chp[Year];
    output;
  end;

  keep College Region InstType SizeCat Year TotalCH Learners CH_per_Learner
       GradPR VAF GPercentFemale GPercentMale;
       /* we dropped Total_CH and Learners of years 1,2 and 3 because we are not needed anymore we extracted required information for our analysis also we dropped inst_type and cat_size and check etc */
run;

Title ' Transpose of Compiled Dataset After Excluding Non-Significant Attributes';
proc print
data=compiled_long;
run;
title;

/**********************************************************************/
/* STEP 11: Exploratory Data Analysis                                 */
/* Ref: lines of code is inspired from lab7,10 worksheets             */                                      
/*                                                                    */
/**********************************************************************/

proc means data=compiled_long
           n mean std min p25 median p75 max;
  class InstType SizeCat Year Region;
  var CH_per_Learner Learners GradPR VAF;
run;

/***********************************************************************/
/* Check how many variables are now in our dataset after tranpose      */
/***********************************************************************/

proc contents data=compiled_long;
run;

/****************************************************************************************************/
/* Note:                                                                                            */
/* As we know by adding normal option it provides normality tests and plots                         */
/* for the justifing non‑parametric analysis to justify this the data is not normally distributed.  */
/* for normal distribution if the Shapiro-wilk P<0.05 reject normality                              */
/* Proc univariate for multiple variables idea comes in mind(self generated code modification)      */
/****************************************************************************************************/

proc univariate data=compiled_long normal; /* Idea got from lab session*/
  var GradPR VAF GPercentFemale GPercentMale CH_per_Learner Learners TotalCH;
  ppplot / normal(mu= est sigma= est) ;
  qqplot / normal(mu=est sigma=est);
  inset n nmiss min q1 median q3 max skew kurt / position= SE ;
run;

/************************************************************************************************************************************************/
/*Comment: Skewness exists, we analyzed that our p which is <0.0001 implies it rejects the normality, that our compiled data is not normalyzed  */
/************************************************************************************************************************************************/

/**********************************************************/
/* Now checking skewness for the compiled_wide dataset    */
/**********************************************************/

proc univariate 
    data= compiled_wide normal ;
    var CHPL_Y1 CHPL_Y2 CHPL_Y3 VAF GradPR Learners_Y1 Learners_Y2 Learners_Y3 TotalCH_Y1 TotalCH_Y2 TotalCH_Y3;
	
    ppplot / normal(mu= est sigma= est) ;
    qqplot / normal(mu= est sigma= est) ;
    inset n nmiss min q1 median q3 max skew kurt / position= SE ;
run;


/*****************************************************************************************************************************************************/
/*Comment: Also, We analyzed till now our long and wide datasets both are skewed so let us do some transformation before doing parametric analysis   */
/*****************************************************************************************************************************************************/

/***********************************************************************************************************/
/*                                                                                                         */
/* Below Analysis and outputs are not menshioned in the Report writing because of limited words count      */
/*                                                                                                         */
/***********************************************************************************************************/

/*-----------------------------------------------------------------------------------------------------------*/

/*****************************************************************************************************/
/* we will perform Log 10 Transformation because our data is positively skewed                       */
/* We will apply transformation to all those variables which are skewed as we analyzed above before  */
/*****************************************************************************************************/

/***********************************************************************/
/*Doing transformation for compiled_wide dataset                       */
/***********************************************************************/

data compiled_wide_log;
    set compiled_wide;

    AvgCHPL_log10        = log10(AvgCHPL);
    AvgLearners_log10    = log10(AvgLearners);
    CHPL_Y1_log10        = log10(CHPL_Y1);
    CHPL_Y2_log10        = log10(CHPL_Y2);
    CHPL_Y3_log10        = log10(CHPL_Y3);
    GPercentFemale_log10 = log10(GPercentFemale);
    GPercentMale_log10   = log10(GPercentMale);
    GradPR_log10         = log10(GradPR);
    Learners_Y1_log10    = log10(Learners_Y1);
    Learners_Y2_log10    = log10(Learners_Y2);
    Learners_Y3_log10    = log10(Learners_Y3);
    TotalCH_Y1_log10     = log10(TotalCH_Y1);
    TotalCH_Y2_log10     = log10(TotalCH_Y2);
    TotalCH_Y3_log10     = log10(TotalCH_Y3);
    VAF_log10            = log10(VAF);
run;

proc print
data=compiled_wide_log;
run;

/***************************************************************/
/*Checking Skewness after log transformation                   */
/***************************************************************/

proc univariate 
    data= compiled_wide_log normal noprint ;
    var CHPL_Y1_log10 CHPL_Y2_log10 CHPL_Y3_log10 Learners_Y1_log10 Learners_Y2_log10 Learners_Y3_log10 TotalCH_Y1_log10 TotalCH_Y2_log10 TotalCH_Y3_log10;
	
    ppplot / normal(mu= est sigma= est) ;
    qqplot / normal(mu= est sigma= est) ;
    inset n nmiss min q1 median q3 max skew kurt / position= SE ;
run;

/***********************************************************/
/* We found skewness still exist after log transformation  */
/* Let us do sqrt transformation                           */
/***********************************************************/

data compiled_wide_sqrt;
    set compiled_wide;

    AvgCHPL_sqrt        = sqrt(AvgCHPL);
    AvgLearners_sqrt    = sqrt(AvgLearners);
    CHPL_Y1_sqrt        = sqrt(CHPL_Y1);
    CHPL_Y2_sqrt        = sqrt(CHPL_Y2);
    CHPL_Y3_sqrt        = sqrt(CHPL_Y3);
    GPercentFemale_sqrt = sqrt(GPercentFemale);
    GPercentMale_sqrt   = sqrt(GPercentMale);
    GradPR_sqrt         = sqrt(GradPR);
    Learners_Y1_sqrt    = sqrt(Learners_Y1);
    Learners_Y2_sqrt    = sqrt(Learners_Y2);
    Learners_Y3_sqrt    = sqrt(Learners_Y3);
    TotalCH_Y1_sqrt     = sqrt(TotalCH_Y1);
    TotalCH_Y2_sqrt     = sqrt(TotalCH_Y2);
    TotalCH_Y3_sqrt     = sqrt(TotalCH_Y3);
    VAF_sqrt            = sqrt(VAF);
run;

proc print
data=compiled_wide_sqrt;
run;

/********************************************************/
/*Checking Skewness after sqrt transformation           */
/********************************************************/

proc univariate 
    data= compiled_wide_sqrt normal;
    var CHPL_Y1_sqrt CHPL_Y2_sqrt CHPL_Y3_sqrt Learners_Y1_sqrt Learners_Y2_sqrt Learners_Y3_sqrt TotalCH_Y1_sqrt TotalCH_Y2_sqrt TotalCH_Y3_sqrt;
	
    ppplot / normal(mu= est sigma= est) ;
    qqplot / normal(mu= est sigma= est) ;
    inset n nmiss min q1 median q3 max skew kurt / position= SE ;
run;

/***********************************************************************/
/* Also We found skewness still exist after squareroot transformation  */
/***********************************************************************/

/**********************************************************************************************/
/*Comparing Skewness after log and sqrt transformation which transformation performed better  */
/**********************************************************************************************/

/*proc univariate 
    data= compiled_wide_sqrt compiled_wide_log normal;
    var CHPL_Y1_sqrt CHPL_Y1_log10 CHPL_Y2_sqrt CHPL_Y2_log10 CHPL_Y3_sqrt CHPL_Y3_log10 Learners_Y1_sqrt Learners_Y1_log10 
    Learners_Y2_sqrt Learners_Y2_log10  Learners_Y3_sqrt Learners_Y3_log10 TotalCH_Y1_sqrt TotalCH_Y1_log10 TotalCH_Y2_sqrt TotalCH_Y2_log10 TotalCH_Y3_sqrt TotalCH_Y3_log10;
	
    ppplot / normal(mu= est sigma= est) ;
    qqplot / normal(mu= est sigma= est) ;
    inset n nmiss min q1 median q3 max skew kurt / position= SE ;
run;*/

/*=====>   The above code is not working we fixed the problem below and found desired result   <=======*/

data combined;
    set compiled_wide_sqrt
        compiled_wide_log;
run;

proc univariate data=combined normal noprint;
    var CHPL_Y1_sqrt CHPL_Y1_log10 CHPL_Y2_sqrt CHPL_Y2_log10 CHPL_Y3_sqrt CHPL_Y3_log10 Learners_Y1_sqrt Learners_Y1_log10 
    Learners_Y2_sqrt Learners_Y2_log10  Learners_Y3_sqrt Learners_Y3_log10 TotalCH_Y1_sqrt TotalCH_Y1_log10 TotalCH_Y2_sqrt TotalCH_Y2_log10 TotalCH_Y3_sqrt TotalCH_Y3_log10;
    *ppplot / normal(mu=est sigma=est);
    qqplot / normal(mu=est sigma=est);
    inset n nmiss min q1 median q3 max skew kurt / position=se;
run;

/**************************************************************************************************************************************/
/* Comment:                                                                                                                           */
/* we analyzed and seen which transformation is better for which variables we will not do log10                                       */
/* transformation for all the variables for variables learners_y1 and y2 squareroot perform well for rest of variables log10 is best  */
/**************************************************************************************************************************************/

/***********************************************************************/
/*Doing log and sqrt transformation for compiled_wide dataset          */
/***********************************************************************/

data compiled_wide_log_sqrt;
    set compiled_wide;

    AvgCHPL_log10        = log10(AvgCHPL);
    AvgLearners_log10    = log10(AvgLearners);
    CHPL_Y1_log10        = log10(CHPL_Y1);
    CHPL_Y2_log10        = log10(CHPL_Y2);
    CHPL_Y3_log10        = log10(CHPL_Y3);
    GPercentFemale_log10 = log10(GPercentFemale);
    GPercentMale_log10   = log10(GPercentMale);
    GradPR_log10         = log10(GradPR);
    Learners_Y1_sqrt    = sqrt(Learners_Y1);
    Learners_Y2_sqrt    = sqrt(Learners_Y2);
    Learners_Y3_log10    = log10(Learners_Y3);
    TotalCH_Y1_log10     = log10(TotalCH_Y1);
    TotalCH_Y2_log10     = log10(TotalCH_Y2);
    TotalCH_Y3_log10     = log10(TotalCH_Y3);
    VAF_log10            = log10(VAF);
run;

proc print
data=compiled_wide_log_sqrt;
run;

/**************Checking final Skewness*************/

proc univariate 
    data= compiled_wide_log_sqrt normal noprint ;
    var CHPL_Y1_log10 CHPL_Y2_log10 CHPL_Y3_log10 Learners_Y1_sqrt Learners_Y2_sqrt Learners_Y3_log10 TotalCH_Y1_log10 TotalCH_Y2_log10 TotalCH_Y3_log10;
	
    ppplot / normal(mu= est sigma= est) ;
    qqplot / normal(mu= est sigma= est) ;
    inset n nmiss min q1 median q3 max skew kurt / position= SE ;
run;

/****************************************************************************************************/
/* we will perform Log 10 Transformation because our long dataset is positively skewed              */
/*We will apply transformation to all those variables which are skewed as we analyzed above before  */
/****************************************************************************************************/

/***********************************************************************/
/*Doing transformation for compiled_long dataset                       */
/***********************************************************************/

data compiled_Long_log;
    set compiled_Long;

    CH_per_Learner_log        = log10(CH_per_Learner);
    GPercentFemale_log10      = log10(GPercentFemale);
    GPercentMale_log10        = log10(GPercentMale);
    GradPR_log10              = log10(GradPR);
    Learners_log10            = log10(Learners);
    TotalCH_log10             = log10(TotalCH);
    VAF_log10                 = log10(VAF);
run;

/***************************************************************/
/*Checking Skewness after log transformation                   */
/***************************************************************/

proc univariate 
    data= compiled_Long_log normal ;
    var TotalCH_log10 VAF_log10 CH_per_Learner_log GPercentFemale_log10 GPercentMale_log10 GradPR_log10 Learners_log10;
	
    ppplot / normal(mu= est sigma= est) ;
    qqplot / normal(mu= est sigma= est) ;
    inset n nmiss min q1 median q3 max skew kurt / position= SE ;
run;



/*********************************************************************************************************************************************************/
/* AS WE CAN SEE AFTER TRANSFORMATION WE REDUCED OUR SKEWNESS BUT NORMALITY TEST FAILED IN SQUAREROOT AND LOG WITH BASE 10 TRANSFORMATION                */
/* SO I THINK NON-PARAMETRIC WOULD BE THE BEST CHOICE FOR OUR FURTHER ANALYSIS, BUT I WILL ALSO TRY PARAMETRIC TEST FOR THE COMPARISON BUT               */
/* NOW I WILL GO WITH PARAMETRIC ANALYSIS BECAUSE WE LEARNED IN CLASS AND EASY TO WRITE CODE.                                                            */
/*********************************************************************************************************************************************************/


/*******************************************************************************************/
/*                                                                                         */
/*                                  Parametric Test Analysis                               */
/*          (Without using transformation according to the Professor Anthony Williams)     */
/*                                                                                         */
/*******************************************************************************************/


/*******************************************************************************************/
/* STEP 22: Independent samples t-test                                                     */
/* Comparison: FE vs Sixth Form institutions                                               */
/* As we know T-Test compares group means assuming distribution is normality distributed   */
/* Ref: Lab 10 and ttest.sas file                                                          */
/*******************************************************************************************/
proc ttest data=compiled_long;
  class InstType;
  var CH_per_Learner;
  
run;

/*********************************************************************************************************/
/*                                                                                                       */
/*Comment: T-test shows high significant difference between the two groups of the colleges indicating    */
/*sixth form colleges deliver more CH per learner then FE. plots also support our discriptive stats that */
/*our data is spread and right skewed in SF Colleges.                                                    */
/*                                                                                                       */
/*********************************************************************************************************/


/***********************************************************************/
/* STEP 23: One-way ANOVA for the analysis of Regional differences     */
/* Ref: lab 10                                                         */
/*                                                                     */
/************************************************************************/

proc glm data=compiled_long;
  class Region;
  model CH_per_Learner = Region;
  means Region / hovtest=levene;

run;
quit;

/**************************************************************************/
/* Comment:                                                               */
/* According to the one-way ANOVA test we examine CH per learner across   */
/* the nine different regions. The output stats indicate that regions are */
/* associated with the significant effects on CH per learner              */
/* (R square = 0.036188) which implies the CH among the regions are not   */
/* uniform. We can see from box plot and the table  Northwest and         */
/* Greater London has high mean values while Southwest and East midlands  */
/* has the lowest showing variations among the region with respect to     */
/* CH per learner. Most important thing is our variance are unequal across*/
/* the region p=0.0012, violates the homogeneity of variance assumptions  */
/* also the sample size is large and because of Central Limit Theorem     */
/* ANOVA behaves robust.                                                  */
/**************************************************************************/


/************************************************************************/
/* STEP 24: One-way ANOVA Institutional size category                   */
/* Ref: lab 10                                                          */
/************************************************************************/

proc glm data=compiled_long;
  class SizeCat;
  model CH_per_Learner = SizeCat;
  means SizeCat / hovtest=levene;
run;
quit;

/*************************************************************************/
/* Comment:                                                              */
/*With the help of PROC GLM we analyze size categories also shows the    */
/* strong differences in CH per learner. Moreover smaller institutions   */
/* tend to have high number of CH per learner then larger ones.          */
/*************************************************************************/


/************************************************************************/
/* STEP 24.1: One-way ANOVA for year                                    */
/* Ref: lab 10                                                          */
/************************************************************************/

proc glm data=compiled_long;
  class Year;
  model CH_per_Learner = Year;
  means Year;
run;
quit;

/***************************************************************************/
/* Comment:                                                                */
/*As we can see the graphical and tabular figures indicates year           */
/*does not significantly influenced on the CH per learner also boxplot     */
/* shows we have almost same median value.                                 */
/***************************************************************************/


/************************************************************************/
/* STEP 24.2: Regression Analysis for Gpercentmale                      */
/* Ref: lab 10                                                          */
/************************************************************************/
proc reg data=compiled_long;
  model CH_per_Learner = Gpercentmale;
  
run;
quit;

/************************************************************************/
/* STEP 24.3: Regression Analysis for gender                            */
/* Ref: lab 10                                                          */
/************************************************************************/
proc reg data=compiled_long;
  model CH_per_Learner = Gpercentfemale;
  
run;
quit;


/**************************************************************************/
/* Comment:                                                               */
/*As we can see the high F and low P value as well as the graph having    */
/* upward and downward slope and narrow shaded area along both the sides  */
/* of  ‘GPercentMale’ and ‘GpercentFemale’ line all these things tells    */
/* us that CH per learner are statistically significant, precise and      */
/* consistent, as R square is 0.0718 indicates effect size is small       */
/* that is 7.18%, model estimates for every 1% increase in male learners  */
/* increase in 35.616 CH per learner while in female case for every       */
/* 1% increase in female learners decrease in 35.616 CH per learner       */
/* as screenshots are attached below. In simple words if higher           */
/* proportion of male learners implies to deliver slightly more           */
/* CH per learner.                                                        */
/*                                                                        */
/**************************************************************************/


/************************************************************************/
/* STEP 24.4: Regression Analysis for VAF                               */
/* Ref: lab 10                                                          */
/************************************************************************/
proc reg data=compiled_long;
  model CH_per_Learner = VAF;

run;
quit;

/************************************************************************************/
/* Comment:                                                                         */
/* Results shows highly significant positive relation between VAF and               */
/* CH per learner. Also, for every one unit increase in VAF cause                   */
/* an increase of 1106.89 in CH per learner. The upward slope and narrow            */
/* confidence interval indicates his precision estimate. Also, estimate             */
/* VAF regression value is 1106.897 and P<0.0001 implies higher the VAF             */
/* values deliver higher CH per learner. Till now in our all previous               */
/* analysis VAF has got the second highest effects on CH per learner after the Size.*/
/*                                                                                  */
/************************************************************************************/

/**************************************************************************/
/* STEP 24.5: Regression Analysis for GradPR                              */
/* Ref: lab 10                                                            */
/**************************************************************************/
proc reg data=compiled_long;
  model CH_per_Learner = GradPR;

run;
quit;

/***************************************************************************/
/* Comment:                                                                */
/*High value of F shows strong linear relationship and P values and        */
/* graphical results indicates significant positive relation between       */
/* Graduate passing rate and CH per learner. Graph shows high estimate     */
/* and confidence interval for Graduation Passing rate(GradPR).            */
/* Till now GradPR is the third most important attribute which impact      */
/* on CH per learner after Size and VAF.                                   */
/*                                                                         */
/***************************************************************************/


/************************************************************************/
/* STEP 25: GLM Model Region and Year (Not included in report)          */
/* Ref: lab 10                                                          */
/* aim is to tests whether regional differences change over the time    */
/* if our result comes                                                  */
/************************************************************************/

proc glm data=compiled_long;
  class Region Year;

  model CH_per_Learner = Region Year Region*Year;

run;
quit;

/************************************************************************/
/*Our two-way ANOVA results shows our model is statistical significant  */
/* but the effect is very small as values indicates in the tables.      */
/* The p value for region shows significant effect across the region    */
/* on CH per learner. While the year (p=0.2914) do not impact on        */
/* CH per learner significantly means over the time CH per learner      */
/* do not get impacted. AS we can see the interaction plot have         */
/* parallel lines implies across the year regional pattern are          */
/* consistent. We can say that region and year are independent          */
/* from each other having no meaningful relation.                       */
/************************************************************************/ 



/************************************************************************/
/* STEP 25.1: Examining the institution type and by size                */
/* Ref: lab 10                                                          */
/* aim is to tests whether institution type change over the size       */
/*                                                                     */
/************************************************************************/

proc glm data=compiled_long;
  class InstType SizeCat;

  model CH_per_Learner = InstType SizeCat InstType*SizeCat;

run;
quit;

/*****************************************************************************************/
/* Comment:                                                                              */
/*Tables and plot both tells us that both the institute type, size category and          */
/* interaction highly impact on the CH per learner. F value = 529.94 with p<0.0001       */
/* tells us that our model is highly significant. As R square = 0.7828 means 78.28%      */
/* is the size impact on CH per learner and these institutional characteristics tells    */
/* 78% of the variation of CH per learner.  We also analyzed that CH per learner are     */
/* higher in SF then FE across all categories, this means SF institutions consistently   */
/* offers more CH per Learner as compared to the FE, means magnitude of these            */
/* advantages depending on the size. We can say that till now what we have analyze       */
/* so far that, institution type and size are the most dominants factors on CH per       */
/* learner.                                                                              */
/*****************************************************************************************/


/*****************************************************************************************/
/* STEP 26: Pearson correlation                                                          */
/* As we know Pearson correlation assumes linear relationships and approximate normality */
/* Ref: lab 10 and step by step book                                                     */
/*****************************************************************************************/

proc corr data=compiled_long pearson;
  var  CH_per_Learner Learners GradPR VAF Year GpercentMale GpercentFemale;
run;

proc print
data=compiled_long;
run;

/************************************************************************************************/
/*Comment:                                                                                      */
/*Overall below output of both the parametric Pearson correlation and non-parametric Spearman   */
/*correlation gives the same output predictions. The metrics below tell us about the relation   */
/*among the variables. I will discuss few main ones. Size, VAF and Graduate passing rate are    */
/*highly correlated and can be consider as institution important associated indicators.         */
/*Negative learner correlation indicates inverse relation means bigger institutions tend        */
/*fewer the contact hours to per learner and vice versa. Also, male have positive while female  */
/*has negative relation with CH per learner.                                                    */
/*Pearson Correlation Variables Summary:                                                        */
/*CH per learner vs Learner, p<0.0001 and r=-0.57093 negative relation, implies higher the      */
/* numbers of the learners are, fewer the CH per learner are.                                   */ 
/*CH per learner vs GradPR, p<0.0001 and r=0.60964 implies second most strongest relationship   */
/* with CH per learner, Higher graduation passing rate implies higher CH per learner.           */
/*CH per learner vs VAF, p<0.0001 and r=0.74306 implies strong relationship, Institution with   */ 
/* high VAF values tends to get high contact hours per learner.                                 */
/*CH Per Learner vs Year, p<0.5022 and r=0.02086 implies no meaningful relation between them.   */
/* Across the years CH per learner remains the same.                                            */ 
/*CH Per Learner vs Gender, p<0.0001 and r=0.28790 for both the male and female, implies weak   */
/* statistically significant relation among genders but not much impactful.                     */
/************************************************************************************************/


/************************************************************************************************/
/* STEP: Simple linear regression (relation between learners and CH)                            */
/* our aim is to check the Outcome of Contact hours per learner to Predict Number of learners   */
/* Ref: lab 10                                                                                  */
/************************************************************************************************/

proc reg data=compiled_long;
  model CH_per_Learner = Learners;
  /* we got negative relation. As our Slope coefficient indicates change in contact hours per learner and R square 
  shows the proportion of var.*/
run;
quit;

/***********************************************************************/
/* STEP   : Multiple linear regression                                 */
/* our aim is to check the Outcome of Contact hours per learner        */
/* to predict the Learners, GradPR, value-added factor (VAF)           */
/* Ref: lab 10                                                         */
/***********************************************************************/

proc reg data=compiled_long;
  model CH_per_Learner = Learners GradPR VAF;
 
run;
quit;

/***********************************************************************/
/* STEP   : One-way ANOVA (institution type)                           */
/* Factor: FE vs Sixth Form                                            */
/* Ref: Chapter 12 – Working with Grouped Data, pp. 191–204            */
/***********************************************************************/

proc glm data=compiled_long;
  class InstType;

  model CH_per_Learner = InstType;
  /* One-way ANOVA tests mean differences */

  means InstType / hovtest=levene;
  /* Levene’s test checks homogeneity of variance
     Ref: Chapter 8, pp. 128–130 */
run;
quit;

/***********************************************************************/
/* STEP   : ANova model (categorical & continuous var)                 */
/* Ref: Chapter 12 – Working with Grouped Observations, pp. 191–204    */
/***********************************************************************/

proc glm data=compiled_long;
  class InstType;

  model CH_per_Learner = InstType Learners;
run;
quit;

/***********************************************************************/
/* STEP   : Model diagnostics (residual inspection)                    */
/* Ref: Chapter 23  Analyzing the SAS Session with the SAS Log         */
/*      pp. 377–399                                                    */
/***********************************************************************/

proc reg data=compiled_long;
  model CH_per_Learner = Learners GradPR VAF;
  plot residual.*predicted.;
  /* we checked the residual plots to check the linearity and homoscedasticity */
run;
quit;

/*******************************************************************************************/
/*                                                                                         */
/*                                   Non-Parametric Test Analysis                          */
/*                                                                                         */
/*******************************************************************************************/


/******************************************************************************************************************/

/* First we will apply Wilcoxon Rank‑Sum test alternative of T-test for the comparison of two groups              */

/******************************************************************************************************************/

/************************************************************************/
/* Step : Wilcoxon Rank‑Sum test                                        */
/* Ref:   Chapter 10 – Acting on Selected Observations, pp. 153–173     */
/*      (Class variables and conditional processing)                    */
/************************************************************************/


proc npar1way data=compiled_long wilcoxon;
  class InstType; /* CLASS defines the grouping variable learned from lab 9 session and Chapter 10, pp. 160–168 step by step guide book */
  var CH_per_Learner;
run;

/***********************************************************************************************************************************************************************/
/* Comment: The p<0.0001 indicates that CH_Per_Learner has significant difference between FE and Sixth Form colleges, Also we can see their rank scores gape which are */
/* approximately 383 and 862 respectively. Moreover the non-parametric test Kruskal-wallis also verifies our prevoius words. i.e(chi-square = 538.4721, p< 0.0001)     */
/* the box plot verifies the above statement that the FE and Sixth form colleges both the groups are statistically significant different.                              */ 
/* A clear plot indicates that Sixth form colleges have higher median and more concentrated CH_Per_learner distribution,                                               */
/* on the other hand FE college have lower as well as more lower variable scores                                                                                       */
/***********************************************************************************************************************************************************************/



/***********************************************************************/
/* STEP: Spearman rank correlation                                     */
/* Ref: Chapter 8 – Working with Numeric Variables, pp. 121–130        */
/*      (Correlation and numeric comparisons)                          */
/***********************************************************************/

proc corr data=compiled_long spearman;
  var CH_per_Learner Learners Year GpercentFemale Gpercentmale GradPR VAF;
run;


/***********************************************************************/
/* STEP: Metadata for appendix                                         */
/* Ref: Chapter 37 Getting Information about Your SAS Data Sets,       */
/*      pp. 731–742                                                    */
/***********************************************************************/

/****************************************************************************/
/*                                                                          */
/*Looking for the contents of both the dataset before and after transpose   */
/*                                                                          */
/****************************************************************************/

title'Contents of the dataset before Transpose'; 
proc contents data=compiled_wide
              out=metadata_final;
run;
title;

title'Contents of the dataset after Transpose'; 
proc contents data=compiled_long
              out=metadata_final;
run;
title;

proc freq data=compiled_long;
run;

/****************************************************************************/
/*                                                                          */
/*Looking for the Stats of both the dataset before and after transpose      */
/*                                                                          */
/****************************************************************************/

title 'Metadata Table for Compiled Wide Dataset';
proc means data=compiled_wide
    n nmiss mean median std min max;
    class InstType;
    ods output Summary=metadata_table;
run;
title;

title 'Metadata Table for Compiled long Dataset';
proc means data=compiled_long
    n nmiss mean median std min max;
    class InstType;
    ods output Summary=metadata_table;
run;
title;


