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

* 7. Quick checks
tab neg_amount_flag
tab reimbursement_flag
tab funded_flag
tab funded_with_comment

* Log-scale histogram of totalamountprediscount >= 0
* Enhanced histogram with publication-quality formatting
histogram log_total, width(0.2) frequency ///
    color(grey%70) lcolor(white) lwidth(vthin) ///
    title("Distribution of Total Amount Requested", size(medium) margin(medium)) ///
    subtitle("Log Scale", size(small) margin(small)) ///
    xtitle("ln(Total Amount Requested)", size(medsmall)) ///
    ytitle("Frequency", size(medsmall)) ///
    xlabel(, labsize(small) grid glcolor(gs12) glpattern(solid)) ///
    ylabel(, labsize(small) angle(horizontal) grid glcolor(gs12) glpattern(solid)) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(small)) ///
    note("Sample: Texas school district E-Rate applications with positive requested amounts" ///
         "Data source: USAC E-Rate Program 2016+ ", size(vsmall))

* Export with high resolution
graph export "`outfile'/Log_Amount_Requested_Density.pdf", replace
graph export "`outfile'/Log_Amount_Requested_Density.eps", replace
	
* Get the 95th percentile of totalamountprediscount >= 0
summarize totalamount_clean, detail   
local p95 = r(p95)     

* Now the histogram (with the local correctly used)
histogram totalamount_clean if totalamount_clean <= `p95', ///
    width(100) frequency ///
    color(green%60) lcolor(white) ///
    title("Total Amount Requested (capped at 95th percentile)") ///
    xtitle("Amount Requested") ytitle("Frequency") ///
    name(hist_capped, replace)
	

