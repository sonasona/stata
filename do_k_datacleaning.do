
* Flag students who have "Need more information" in any answer choice
insheet using "`filename1'.txt", delim("|")
drop if inactivatereason!="-"
keep osisid firstname lastname daytimephonenumber eveningphonenumber kappphone programcode* additional*

gen needinfo=0
foreach var of varlist additionalinformation* {
	replace needinfo=1 if `var'=="Need more information"
}

tab needinfo
* 81 students
keep if needinfo==1

foreach x of numlist 1/12 {
rename additionalquestion`x'_1 additionalquestionA_`x'
rename additionalquestion`x'_2 additionalquestionB_`x'
rename additionalquestion`x'_3 additionalquestionC_`x'
rename additionalquestion`x'_4 additionalquestionD_`x'
rename additionalquestion`x'_5 additionalquestionE_`x'

rename additionalinformation`x'_1 additionalinformationA_`x'
rename additionalinformation`x'_2 additionalinformationB_`x'
rename additionalinformation`x'_3 additionalinformationC_`x'
rename additionalinformation`x'_4 additionalinformationD_`x'
rename additionalinformation`x'_5 additionalinformationE_`x'
}

reshape long programcode additionalquestionA_ additionalquestionB_ additionalquestionC_ additionalquestionD_ additionalquestionE_ additionalinformationA_ additionalinformationB_ additionalinformationC_ additionalinformationD_ additionalinformationE_, i(osisid) j(choice)
drop if programcode=="-"
keep if inlist("Need more information",additionalinformationA_,additionalinformationB_,additionalinformationC_,additionalinformationD_,additionalinformationE_)
distinct osisid

*br
clear


* Flag duplicate applicants
insheet using "`filename2'.txt", delim("|")

drop if inactivatereason!="-"
tostring dateofbirth, replace

gen student_v1= firstname+ lastname+ dateofbirth+ daytimephonenumber
distinct student_v1

gen ct_choices=0
foreach x of numlist 1/12 {
	replace ct_choices=ct_choices+1 if programcode`x'!="-"
}
tab ct_choices
* 141 students with 0 choices

sort student_v1 dateapplication ct_choices
by student_v1: gen ct_obs_v1=_N

* flag students who need to have application mapped to student ID
* if observation is the one to keep, and student pair of obs has exactly one NYC student ID, and that observation is not an NYC ID, then bring up student ID from other obs
gen is_nycid=1 if osisid<300000000
by student_v1: egen ct_nycid=sum(is_nycid)

gen long id_for_map=.
sort student_v1 osisid
by student_v1: replace id_for_map = osisid[_n-1] if is_nycid!=1 & ct_nycid==1 & ct_obs_v1>1
format id_for_map %9.0f

gsort student_v1 dateapplication ct_choices -osisid
gen apptodrop=1 if ct_choices==0 & ct_obs_v1>1
preserve
keep if apptodrop==1
tempfile drops
save `drops', replace
restore
drop if apptodrop==1
drop ct_obs_v1
by student_v1: gen ct_obs_v1=_N

* just keep more recent app, regardless of number of choices
sort student_v2 osisid
by student_v1: replace apptodrop=1 if _n==1 & ct_obs_v1==2
preserve
keep if apptodrop==1
append using `drops'
save `drops', replace
restore
drop if apptodrop==1

tempfile data1
save `data1', replace

/*
gen isnycid=osisid if osisid<300000000
by student_all: egen nycid=max(isnycid)
*/

* Duplicates 2: sieve name, DOB, zip code, house number
* create sieve versions of name
* add on DOB and zip code

drop ct_nycid
egen fname1=sieve(firstname), keep(a)
egen lname1=sieve(lastname), keep(a)
gen namedob=dateofbirth+fname1+lname1
sort namedob
distinct student_v1

tostring zip, replace
replace kappzipcode=zip if kappzip=="-"
replace kappstreetnumber=housenumber if kappstreetnumber=="-"
egen streetnum1=sieve(kappstreetnumber), keep(a n)
gen student_v2= namedob+kappzipcode+streetnum1
sort student_v2 dateapplication
by student_v2: gen ct_obs_v2=_N

sort student_v2 osisid
by student_v2: egen ct_nycid=sum(is_nycid)
by student_v2: replace id_for_map = osisid[_n-1] if is_nycid!=1 & ct_nycid==1 & ct_obs_v2>1
format id_for_map %9.0f

replace apptodrop=1 if ct_choices==0 & ct_obs_v2>1
drop matchedprogramcode- multiple4samefinalprogramcode
drop additional*
drop lateprogrampriority1- v680
preserve
keep if apptodrop==1
tempfile drops2
save `drops2', replace
restore
drop if apptodrop==1
drop ct_obs_v2
by student_v2: gen ct_obs_v2=_N

* just keep more recent app, regardless of number of choices
gsort student_v2 dateapplication ct_choices -osisid 
by student_v2: replace apptodrop=1 if _n==1 & ct_obs_v2==2
replace kappstreetname=streetname if kappstreetname=="-"
order osisid id_for_map apptodrop
br osisid- dateapplicationenteredinsems firstname lastname dateofbirth adultfirstname adultlastname kappstreetnumber kappstreetname kappzip daytimephone if ct_obs_v2>1
* after manual review, update one K team to look into that I'm not sure of
replace apptodrop=. if osisid==888805768
replace ct_obs_v2=1 if inlist(osisid,888805768,240779363)

preserve
keep if apptodrop==1
append using `drops2'
save `drops2', replace
restore
drop if apptodrop==1

tempfile data2
save `data2', replace

* Duplicates 3
* check name+adult name

drop ct_nycid
gen name=fname1+lname1

gen student_v3=name+adultfirstname
sort student_v3 dateapplication
by student_v3: gen ct_obs_v3=_N

sort student_v3 osisid
by student_v3: egen ct_nycid=sum(is_nycid)
by student_v3: replace id_for_map = osisid[_n-1] if is_nycid!=1 & ct_nycid==1 & ct_obs_v3>1
format id_for_map %9.0f

replace apptodrop=1 if ct_choices==0 & ct_obs_v3>1
preserve
keep if apptodrop==1
tempfile drops3
save `drops3', replace
restore
drop if apptodrop==1
drop ct_obs_v3
by student_v3: gen ct_obs_v3=_N

* just keep more recent app, regardless of number of choices
gsort student_v3 dateapplication ct_choices -osisid 
by student_v3: replace apptodrop=1 if _n==1 & ct_obs_v3>1
order osisid id_for_map apptodrop
br osisid- dateapplicationenteredinsems firstname lastname dateofbirth adultfirstname adultlastname kappstreetnumber kappstreetname kappzip daytimephone if ct_obs_v3>1
* after manual review, update one K team to look into that I'm not sure of

replace ct_obs_v3=1 if inlist(osisid,241405000,241670207,240669580,243461282,239697329,888310511,888806793,234178069,243230174) | inlist(osisid,242130540,243107240,888309362,888325047)
replace apptodrop=. if inlist(osisid,241405000,241670207,240669580,243461282,239697329,888310511,888806793,234178069,243230174) | inlist(osisid,242130540,243107240,888309362,888325047)

preserve
keep if apptodrop==1
append using `drops3'
save `drops3', replace
restore
drop if apptodrop==1

tempfile data3
save `data3', replace


* Duplicates 4 - informal review of same phone number
replace daytimephonenumber=subinstr(daytimephonenumber," ","",10)
replace daytimephonenumber=subinstr(daytimephonenumber,"-","",10)
replace daytimephonenumber="" if daytimephonenumber=="0000000000"
replace daytimephonenumber=kappphone if inlist(daytimephonenumber,"","-")
sort daytimephone
by daytimephone: gen ct_phone=_N
sort daytimephone name
br osisid- dateapplicationenteredinsems firstname lastname dateofbirth adultfirstname adultlastname kappstreetnumber kappstreetname kappzip daytimephone  if ct_phone>2 & !inlist(daytimephone,"","-")
br osisid- dateapplicationenteredinsems firstname lastname dateofbirth adultfirstname adultlastname kappstreetnumber kappstreetname kappzip daytimephone  if ct_phone==2 & !inlist(daytimephone,"","-")

* Duplicates 5 - first 3 of first name, full last name, date of birth, house number
drop ct_nycid
gen student_v4=substr(fname1,1,3)+lname1+dateofbirth+streetnum1

sort student_v4 dateapplication
by student_v4: gen ct_obs_v4=_N

sort student_v4 osisid
by student_v4: egen ct_nycid=sum(is_nycid)
by student_v4: replace id_for_map = osisid[_n-1] if is_nycid!=1 & ct_nycid==1 & ct_obs_v4>1
format id_for_map %9.0f

*br osisid- dateapplicationenteredinsems firstname lastname dateofbirth adultfirstname adultlastname kappstreetnumber kappstreetname kappzip daytimephone gender if ct_obs_v4>1
drop if apptodrop==1

