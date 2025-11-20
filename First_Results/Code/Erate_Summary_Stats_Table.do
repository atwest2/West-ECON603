clear all
set more off

global projects: env Projects
global storagea: env storagea

local dataready = "$storagea/TX_Erate_2016_post.csv"
local outfile =  "$projects/ECON603/First_Results"

* Import Data
import delimited using "`dataready'", clear

gen totalamountprediscount_num = real(subinstr(subinstr(totalamountprediscount, "$", "", .), ",", "", .))
gen totalrequestedinvoice_num   = real(subinstr(subinstr(totalrequestedinvoicelineamount, "$", "", .), ",", "", .))
gen totalapprovedinvoice_num   = real(subinstr(subinstr(totalapprovedinvoicelineamount, "$", "", .), ",", "", .))

keep if applicanttype == "School District"

gen totalamount_clean = totalrequestedinvoice_num
replace totalamount_clean = . if totalrequestedinvoice_num <= 0

gen log_total = ln(totalamount_clean) if totalamount_clean > 0

gen funded_flag         = (totalapprovedinvoice_num > 0)
gen neg_amount_flag     = (totalrequestedinvoice_num <= 0)
gen reimbursement_flag  = (reimbursementrequestdecisioncode != "")
gen funded_with_comment = reimbursement_flag & funded_flag

* Get variable statistics and store in matrices
local financial_vars totalrequestedinvoice_num totalapprovedinvoice_num log_total
local flag_vars discountrate funded_flag neg_amount_flag reimbursement_flag funded_with_comment

* Matrix for financial variables (mean, sd, p25, p50, p75)
matrix desc_financial = J(3, 4, .)

* Matrix for flag variables (mean, sd only)
matrix desc_flags = J(5, 2, .)

* Financial variables: mean, sd, p25, p50, p75
local i = 1
foreach var of local financial_vars {
    summ `var', detail
    matrix desc_financial[`i', 1] = r(mean)
    matrix desc_financial[`i', 2] = r(sd)
    matrix desc_financial[`i', 3] = r(p25)
    matrix desc_financial[`i', 4] = r(p75)
    local ++i
}

* Flag variables: mean, sd only
local i = 1
foreach var of local flag_vars {
    summ `var'
    matrix desc_flags[`i', 1] = r(mean)
    matrix desc_flags[`i', 2] = r(sd)
    local ++i
}

* Create data for Table

clear
set obs 30
gen n = _n

* Create the data values
forvalues j = 1/5 {
    gen desc_financial`j' = .
}
forvalues j = 1/2 {
    gen desc_flags`j' = .
}

* CORRECTED: Fill in financial data from matrix (rows 12-14)
* Row 12: totalamount_clean (Requested Invoice Amount)
replace desc_financial1 = desc_financial[1, 1] if n == 12
replace desc_financial2 = desc_financial[1, 2] if n == 12
replace desc_financial3 = desc_financial[1, 3] if n == 12
replace desc_financial4 = desc_financial[1, 4] if n == 12

* Row 13: totalapprovedinvoice_num (Approved Invoice Amount)
replace desc_financial1 = desc_financial[2, 1] if n == 13
replace desc_financial2 = desc_financial[2, 2] if n == 13
replace desc_financial3 = desc_financial[2, 3] if n == 13
replace desc_financial4 = desc_financial[2, 4] if n == 13

* Row 14: log_total (Log Requested Amount)
replace desc_financial1 = desc_financial[3, 1] if n == 14
replace desc_financial2 = desc_financial[3, 2] if n == 14
replace desc_financial3 = desc_financial[3, 3] if n == 14
replace desc_financial4 = desc_financial[3, 4] if n == 14

* CORRECTED: Fill in flag data from matrix (rows 17-21)
* Row 17: discountrate
replace desc_flags1 = desc_flags[1, 1] if n == 17
replace desc_flags2 = desc_flags[1, 2] if n == 17

* Row 18: funded_flag
replace desc_flags1 = desc_flags[2, 1] if n == 18
replace desc_flags2 = desc_flags[2, 2] if n == 18

* Row 19: neg_amount_flag
replace desc_flags1 = desc_flags[3, 1] if n == 19
replace desc_flags2 = desc_flags[3, 2] if n == 19

* Row 20: reimbursement_flag
replace desc_flags1 = desc_flags[4, 1] if n == 20
replace desc_flags2 = desc_flags[4, 2] if n == 20

* Row 21: funded_with_comment
replace desc_flags1 = desc_flags[5, 1] if n == 21
replace desc_flags2 = desc_flags[5, 2] if n == 21

* Format numbers
foreach j of numlist 1/5 {
    replace desc_financial`j' = round(desc_financial`j', 0.001)
    gen desc_financial`j'_str = ""
    replace desc_financial`j'_str = string(desc_financial`j', "%12.0fc") if desc_financial`j' > 1000
    replace desc_financial`j'_str = string(desc_financial`j', "%9.3f") if desc_financial`j' <= 1000 & desc_financial`j' >= 0.001
    replace desc_financial`j'_str = string(desc_financial`j', "%9.3f") if desc_financial`j' < 0
    replace desc_financial`j'_str = "0" if desc_financial`j' == 0
    replace desc_financial`j'_str = subinstr(desc_financial`j'_str, ".000", "", .)
}

foreach j of numlist 1/2 {
    replace desc_flags`j' = round(desc_flags`j', 0.001)
    gen desc_flags`j'_str = ""
    replace desc_flags`j'_str = string(desc_flags`j', "%12.0fc") if desc_flags`j' > 1000
    replace desc_flags`j'_str = string(desc_flags`j', "%9.3f") if desc_flags`j' <= 1000 & desc_flags`j' >= 0.001
    replace desc_flags`j'_str = string(desc_flags`j', "%9.3f") if desc_flags`j' < 0
    replace desc_flags`j'_str = "0" if desc_flags`j' == 0
    replace desc_flags`j'_str = subinstr(desc_flags`j'_str, ".000", "", .)
}

* Create LaTeX components
gen all1_0 = ""    
gen all0and = ""   
gen all1and = ""   
gen all2and = ""   
gen all3and = ""     

* -------- Table Environment --------
replace all1_0 = "\begin{table}[htbp]" if n == 1
replace all1_0 = "\centering" if n == 2
replace all1_0 = "\caption{Summary Statistics for E-Rate Funding Requests}" if n == 3
replace all1_0 = "\label{tab:erate_summary_stats}" if n == 4
replace all1_0 = "\begin{threeparttable}" if n == 5
replace all1_0 = "\begin{tabular}{ l c c c c }" if n == 6
replace all1_0 = "\toprule" if n == 7

* -------- Column Headers --------
replace all1_0 = " " if n == 8
replace all0and = " & \textbf{Mean}" if n == 8
replace all1and = " & \textbf{Std. Dev.}" if n == 8
replace all2and = " & \textbf{25th pct.}" if n == 8
replace all3and = " & \textbf{75th pct.}" if n == 8

replace all1_0 = " " if n == 9
replace all0and = " & (1)" if n == 9
replace all1and = " & (2)" if n == 9
replace all2and = " & (3)" if n == 9
replace all3and = " & (4)" if n == 9

replace all1_0 = "\midrule" if n == 10

* -------- Panel a: Financial Amounts --------
replace all1_0 = "\multicolumn{5}{l}{\underline{\textbf{Panel a. Financial Amounts}}}" if n == 11

* Financial variables
replace all1_0 = "   \hspace{2mm} \textbf{\textit{Requested Invoice Amount}}" if n == 12
replace all0and = " & " + desc_financial1_str if n == 12
replace all1and = " & " + desc_financial2_str if n == 12
replace all2and = " & " + desc_financial3_str if n == 12
replace all3and = " & " + desc_financial4_str if n == 12

replace all1_0 = "   \hspace{2mm} \textbf{\textit{Approved Invoice Amount}}" if n == 13
replace all0and = " & " + desc_financial1_str if n == 13
replace all1and = " & " + desc_financial2_str if n == 13
replace all2and = " & " + desc_financial3_str if n == 13
replace all3and = " & " + desc_financial4_str if n == 13

replace all1_0 = "   \hspace{2mm} \textbf{\textit{Log Requested Amount}}" if n == 14
replace all0and = " & " + desc_financial1_str if n == 14
replace all1and = " & " + desc_financial2_str if n == 14
replace all2and = " & " + desc_financial3_str if n == 14
replace all3and = " & " + desc_financial4_str if n == 14

replace all1_0 = " " if n == 15

* -------- Panel b: Flags and Status --------
replace all1_0 = "\multicolumn{5}{l}{\underline{\textbf{Panel b. Flags and Status}}}" if n == 16

* Flag variables
replace all1_0 = "   \hspace{2mm} \textbf{\textit{Discount Rate}}" if n == 17
replace all0and = " & " + desc_flags1_str if n == 17
replace all1and = " & " + desc_flags2_str if n == 17
replace all2and = " & " if n == 17
replace all3and = " & " if n == 17

replace all1_0 = "   \hspace{2mm} \textbf{\textit{Funded Flag}}" if n == 18
replace all0and = " & " + desc_flags1_str if n == 18
replace all1and = " & " + desc_flags2_str if n == 18
replace all2and = " & " if n == 18
replace all3and = " & " if n == 18

replace all1_0 = "   \hspace{2mm} \textbf{\textit{Negative Requested Amount Flag}}" if n == 19
replace all0and = " & " + desc_flags1_str if n == 19
replace all1and = " & " + desc_flags2_str if n == 19
replace all2and = " & " if n == 19
replace all3and = " & " if n == 19

replace all1_0 = "   \hspace{2mm} \textbf{\textit{Reimbursement Flag}}" if n == 20
replace all0and = " & " + desc_flags1_str if n == 20
replace all1and = " & " + desc_flags2_str if n == 20
replace all2and = " & " if n == 20
replace all3and = " & " if n == 20

replace all1_0 = "   \hspace{2mm} \textbf{\textit{Funded with Comment}}" if n == 21
replace all0and = " & " + desc_flags1_str if n == 21
replace all1and = " & " + desc_flags2_str if n == 21
replace all2and = " & " if n == 21
replace all3and = " & " if n == 21

* -------- Table Footer --------
replace all1_0 = "\bottomrule" if n == 22
replace all1_0 = "\end{tabular}" if n == 23

* -------- threeparttable Footnote --------
replace all1_0 = "\footnotesize" if n == 24
replace all1_0 = "\textit{Notes:} This table reports summary statistics for E-Rate funding requests submitted by public school districts in Texas. Amount Requested refers to the total pre-discount funding amount submitted on Form 471. Approved Amount is the total amount approved for reimbursement. Log Total Amount is the natural logarithm of the requested amount after removing zero or negative values. Discount Rate is the applicant's E-Rate discount percentage based on the percentage of students on the National School Lunch Program in the district. Binary indicator variables are defined as follows: Funded Flag equals 1 if any portion of the request was approved; Negative Amount Flag equals 1 for filings with nonpositive or invalid pre-discount amounts; Reimbursement Flag equals 1 if the request includes a reimbursement decision code; and Funded with Comment equals 1 for requests that were both funded and accompanied by a reimbursement decision code. Percentile columns reflect the empirical 25th, 50th (median), and 75th percentiles of each distribution." if n == 25
replace all1_0 = "\end{threeparttable}" if n == 26
replace all1_0 = "\end{table}" if n == 27

* Combine components into final line
gen line = all1_0 + all0and + all1and + all2and + all3and

* Add line breaks where needed
replace line = line + " \\" if !missing(all1_0) & !regexm(all1_0, "rule|tabular|threeparttable|tablenotes|table|caption|label|centering") & n < 23

* Special handling for specific rows
replace line = line + " \\" if n == 11   // Panel header A
replace line = line + " \\" if n == 15  // Spacing row
replace line = line + " \\" if n == 16  // Panel header B

* Remove line breaks from rules and table start/end
replace line = subinstr(line, " \\", "", .) if regexm(all1_0, "rule|tabular|threeparttable|tablenotes|table|caption|label|centering") 

* Clean up
replace line = strtrim(line)
replace line = subinstr(line, "  ", " ", .)

* Remove rows that are completely empty
drop if missing(line)

* Export
cd $outfile
outsheet line using "`outfile'/summary_stats_table.tex", noquote nonames replace
