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
use "${savedir}\state_month_singleYear_15_49_allDeaths_2000_2020", clear

gen age_group = (age >= 21) + (age >= 30) + (age >= 40)

global DEATH_TYPES allDeaths

collapse (mean) statecode (sum) $DEATH_TYPES (sum) population, by(state year month age_group)

merge m:1 statecode using ${savedir}\legalization, keepusing(y_e y_l)

drop if y_e == .
drop _merge

gen date = year + month / 12

gen months_post_effective = 12 * (date - y_e)
gen months_post_licensed = 12 * (date - y_l)

drop if (months_post_effective < -36 | months_post_effective > 36) & (months_post_licensed < -36 | months_post_licensed > 36)

replace months_post_effective = round(months_post_effective, 1)
replace months_post_licensed = round(months_post_licensed, 1)

foreach death in $DEATH_TYPES {
	gen `death'_rate = `death' / (population / 100000)
	
	replace `death'_rate = -1 if `death'_rate == 0
	
	gen log_`death'_rate = log(`death'_rate)
}
	

global OPTIONS effective licensed
global AGE_GROUP 0 1 2 3 // 0 (15-20); 1 (21-29); 2 (30-39); 3 (40-49)


foreach t in $OPTIONS {
	global LEADS_`t'
	global LAGS_`t'



	forval month = 2/36{
		gen lead_`month'_`t' = (months_post_`t' == -`month')
		
		global LEADS_`t' ${LEADS_`t'} lead_`month'_`t'
	}

	forval month = 0/36 {
		gen lag_`month'_`t' = (months_post_`t' == `month')
		
		global LAGS_`t' ${LAGS_`t'} lag_`month'_`t'
	}
}


// keep if age == 21



foreach t in $OPTIONS {
	foreach death in $DEATH_TYPES {
		sum months_post_`t'
		reghdfe log_`death'_rate ${LEADS_`t'} ${LAGS_`t'}, absorb(statecode date)
	}
}


local x_axis_name = "Months Relative to Legalization of Recreational Marijuana Use"

foreach t in $OPTIONS {
	foreach group in $AGE_GROUP {
		preserve
		
			keep if age_group == `group'
			
			local lower_age = 15 * (`group' == 0) + 21 * (`group' == 1) + 30 * (`group' == 2) + 40 * (`group' == 3)
			local upper_age = 20 * (`group' == 0) + 29 * (`group' == 1) + 39 * (`group' == 2) + 49 * (`group' == 3)
			
			
			reghdfe log_allDeaths_rate ${LEADS_`t'} ${LAGS_`t'}, absorb(statecode date)
		

			gen coef_`t' = .
			gen se_`t' = .

			local month = -36
			foreach q in ${LEADS_`t'} {
				replace coef_`t' = _b[`q'] if months_post_`t' == `month'
				replace se_`t' = _se[`q'] if months_post_`t' == `month'
				
				local month = `month' + 1
			}

				replace coef_`t' = 0 if months_post_`t' == -1
				replace se_`t' = 0 if months_post_`t' == -1

			local month = 0
			foreach q in ${LAGS_`t'} {
				replace coef_`t' = _b[`q'] if months_post_`t' == `month'
				replace se_`t' = _se[`q'] if months_post_`t' == `month'
				
				local month = `month' + 1
			}

			gen lb_`t' = coef_`t' - 1.96*se_`t'
			gen ub_`t' = coef_`t' + 1.96*se_`t'
			
			drop if months_post_`t' < -36 | months_post_`t' > 36
			


			twoway rcap lb_`t' ub_`t' months_post_`t', color(gs11) sort || ///
				line coef_`t' months_post_`t', connect(L) lcolor(black) lpattern(solid) ///
				xline(0, lpattern(.)) yline(0, lpattern(.)) ///
				xsc(range(-36 36)) xmtick(-36(6)36) xlabel(-36(6)36) ///
				ytitle("Log(Deaths per 100,000)") ///
				xtitle(`x_axis_name') ///
				title("Death Rate for `lower_age'- to `upper_age'-Year-Olds") ///
				legend(off) name(estudy_`t'_ageGroup_`group', replace)
				
			graph save "${graphdir}\estudy_`t'_ageGroup_`group'_month.gph", replace
			graph export "${graphdir}\estudy_`t'_ageGroup_`group'_month.png", replace
			

		restore
	}
	local x_axis_name = "Months Relative to Legalization of Licensed Sale of Recreational Marijuana"
}
