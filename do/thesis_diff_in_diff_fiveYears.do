*******************************************************************
* Name: Creighton Morgenfeld          						            
* Date: 
* Purpose: this program serves as a base shell for all stata do files 
*******************************************************************

*** This next line is the path to this .do file, you can cut and paste this path into stata to run the .do file
* do C:\Users\Creighton.Morgenfeld\Documents\AY23-2\SS489C\do\ss489c-replication2.do

********************************
* Standard Stata Configuration
********************************
clear all
set more off
cap log close

set scheme sj

global dir "C:\Users\Creighton\Documents\Stata\Thesis"  // copy actual file path inside the quotes on this line

global dodir "$dir\do"
global rawdir "$dir\raw"
global savedir "$dir\finaldta"
global logdir "$dir\log"
global graphdir "$dir\graph"
global tabledir "$dir\table"

* Set your directory
cd "${dir}"

* Start a log file, which is the text file that keeps all of the output from a Stata run
// log using "${logdir}\Thesis.log", replace


*** This next line loads the data from your .dta file
use "${savedir}\state_year_fiveYear_15_29", clear


global DEATH_TYPES allDeaths intentionalSelfHarm transportDeaths

collapse (mean) statecode (sum) $DEATH_TYPES (sum) population, by(state year ageGroup)

merge m:1 statecode using ${savedir}\legalization, keepusing(y_e y_l)

drop if y_e == .
drop _merge

gen post_effective = year > y_e
gen post_licensed = year > y_l

gen years_post_effective = year - y_e
gen years_post_licensed = year - y_l

foreach death in $DEATH_TYPES {
	gen `death'_rate = `death' / (population / 100000)
	
	replace `death'_rate = -1 if `death'_rate == 0
		
	gen log_`death'_rate = log(`death'_rate)
}
	

global OPTIONS effective licensed
global AGEGROUP 0 1 2 // 0 (15-20); 1 (21-29); 2 (30-39); 3 (40-49)

// keep if age == 21

label var log_allDeaths_rate "Log All Deaths"
label var log_intentionalSelfHarm_rate "Log Intentional Self Harm Deaths"
label var log_transportDeaths_rate "Log Transport Deaths"

local type_name = "Legalization of Recreational Marijuana Use"

foreach t in $OPTIONS {
	foreach group in $AGEGROUP {
		est clear
		preserve 
		
		keep if ageGroup == `group'
		
		local lower_age = 15 * (`group' == 0) + 20 * (`group' == 1) + 25 * (`group' == 2)
		local upper_age = 19 * (`group' == 0) + 24 * (`group' == 1) + 29 * (`group' == 2)
		
		drop if abs(years_post_`t') > 3
			
		foreach death in $DEATH_TYPES {
			eststo: reghdfe log_`death'_rate post_`t', absorb(statecode year)
		}
		esttab using "${tabledir}\diff_in_diff_`t'_`group'.tex", replace title("`type_name' on Death Rate for `lower_age'- to `upper_age'-Year-Olds") label
		
		restore
	}
	local type_name = "Licensed Sale of Recreational Marijuana"
}

esttab, label

local type_name = "Legalization of Recreational Marijuana Use"

est clear 

foreach t in $OPTIONS {
	
// 	drop if abs(years_post_`t') > 3
		
	foreach group in $AGEGROUP {
		preserve
		keep if ageGroup == `group'
		
		eststo: reghdfe log_allDeaths_rate post_`t', absorb(statecode year)
		sum log_allDeaths_rate
		estadd scalar mean_rate = r(mean)
		
		restore
	}
			
}

esttab using "${tabledir}\diff_in_diff_`t'_allDeaths.tex", replace ///
	se ///
	noconstant ///
	scalars(mean_rate) ///
	collabels(none) ///
	eqlabels("15-19" "20-24" "25-29" "15-19" "20-24" "25-29") /// 
	coeflabels("Post Effective" "Post Licensed") ///
	title("`type_name' on All Death Death Rate") label

esttab, collabels(none) ///
	se ///
	noconstant ///
	scalars(mean_rate) ///
	eqlabels("15-19" "20-24" "25-29" "15-19" "20-24" "25-29") /// 
	coeflabels("Post Effective" "Post Licensed") ///
	title("`type_name' on All Death Death Rate") label
	
	
	

local type_name = "Legalization of Recreational Marijuana Use"

est clear 

foreach t in $OPTIONS {
	
// 	drop if abs(years_post_`t') > 3

	local bad_states 4 9 17 24 26 27 29 30 34 35 36 39 51
	foreach s of local bad_states {
		drop if statecode == `s'
	}
	
	keep if round(abs(years_post_`t')) <= 3
		
	foreach group in $AGEGROUP {
		preserve
		keep if ageGroup == `group'
		
		eststo: reghdfe log_allDeaths_rate post_`t', absorb(statecode year)
		sum log_allDeaths_rate
		estadd scalar mean_rate = r(mean)
		
		restore
	}
			
}

esttab using "${tabledir}\diff_in_diff_`t'_allDeaths_pruned.tex", replace ///
	se ///
	noconstant ///
	scalars(mean_rate) ///
	collabels(none) ///
	eqlabels("15-19" "20-24" "25-29" "15-19" "20-24" "25-29") /// 
	coeflabels("Post Effective" "Post Licensed") ///
	title("`type_name' on All Death Death Rate") label

esttab, collabels(none) ///
	se ///
	noconstant ///
	scalars(mean_rate) ///
	eqlabels("15-19" "20-24" "25-29" "15-19" "20-24" "25-29") /// 
	coeflabels("Post Effective" "Post Licensed") ///
	title("`type_name' on All Death Death Rate") label
