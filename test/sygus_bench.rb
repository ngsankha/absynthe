require "test_helper"

## No way to propagate information to other types. Predicate domain needed?

class SygusTest < Minitest::Test
  extend SygusTestRunner

  # Experiment
  # run_sygus_test('./test.sl',
  #   {:name => StringLenExt.var('name')}, StringLenExt.val(3))

  # Used in overview for the paper
  # name_var = StringLenExt.var('name')
  # res = StringLenExt.val(name_var.attrs[:val] - 3)
  # res.asserts.push(res.attrs[:val] > 0)
  # run_sygus_test('./sygus-strings/bikes.sl', {:name => name_var},
  #   res)

  run_sygus_test('./sygus-strings/bikes.sl')
  run_sygus_test('./sygus-strings/dr-name.sl',
    {:name => StringPrefix.top}, StringPrefix.val("Dr. ", false))
  run_sygus_test('./sygus-strings/firstname.sl')

  # TIMEOUT
  # run_sygus_test('./sygus-strings/initials.sl',
  #   {:name => ProductDomain.top}, ProductDomain.val(StringSuffix.val(".", false), StringLength.val(4, 4)))

  # (str.substr name (str.indexof name " " 0) (str.len name))
  run_sygus_test('./sygus-strings/lastname.sl')

  run_sygus_test('./sygus-strings/name-combine-2.sl',
      {:firstname => StringSuffix.top,
       :lastname  => StringSuffix.top}, StringSuffix.val(".", false))

  # (str.++ (str.++ (str.++ (str.substr firstname 0 1) ".") " ") lastname)
  run_sygus_test('./sygus-strings/name-combine-3.sl',
      {:firstname => StringSuffix.top,
       :lastname  => StringSuffix.var('lname')}, StringSuffix.var('lname'))

  # The following 2 are variants of the above benchmark with different domains

  # lname_var = StringLenExt.var('lname')
  # final_res = StringLenExt.val(lname_var.attrs[:val] + 3)
  # final_res.asserts.push(final_res.attrs[:val] > 0)
  # run_sygus_test('./sygus-strings/name-combine-3.sl',
  #     {:firstname => ProductDomain.top,
  #      :lastname  => ProductDomain.val(StringSuffix.var('lname'), lname_var)},
  #     ProductDomain.val(StringSuffix.var('lname'), final_res))

  # lname_var = StringLenExt.var('lname')
  # final_res = StringLenExt.val(lname_var.attrs[:val] + 3)
  # final_res.asserts.push(final_res.attrs[:val] > 0)
  # run_sygus_test('./sygus-strings/name-combine-3.sl',
  #     {:firstname => StringLenExt.top,
  #      :lastname  => lname_var},
  #     final_res)

  # (str.++ (str.++ lastname (str.++ "," (str.++ " " (str.at firstname 0)))) ".")
  # TIMEOUT
  # run_sygus_test('./sygus-strings/name-combine-4.sl',
  #     {:firstname  => ProductDomain.val(StringPrefix.top,          StringSuffix.top),
  #      :lastname   => ProductDomain.val(StringPrefix.var('lname'), StringSuffix.top)},
  #     ProductDomain.val(StringPrefix.var('lname'), StringSuffix.val('.', false)))

  run_sygus_test('./sygus-strings/name-combine.sl')
  run_sygus_test('./sygus-strings/phone-1.sl')

  # TIMEOUT
  # run_sygus_test('./sygus-strings/phone-10.sl')

  run_sygus_test('./sygus-strings/phone-2.sl')

  # TIMEOUT
  # run_sygus_test('./sygus-strings/phone-3.sl',
  #   {:name => StringLenExt.val(11)}, StringLenExt.val(13))

  run_sygus_test('./sygus-strings/phone-4.sl')

  run_sygus_test('./sygus-strings/phone-5.sl')

  run_sygus_test('./sygus-strings/phone-6.sl',
    {:name => StringLenExt.var('name')}, StringLenExt.val(3))
  run_sygus_test('./sygus-strings/phone-7.sl',
    {:name => StringLenExt.var('name')}, StringLenExt.val(3))
  run_sygus_test('./sygus-strings/phone-8.sl',
    {:name => StringLenExt.var('name')}, StringLenExt.val(3))

  # TIMEOUT
  # name_var = StringLenExt.var('name')
  # res = StringLenExt.val(name_var.attrs[:val] - 1)
  # res.asserts.push(res.attrs[:val] > 0)
  # run_sygus_test('./sygus-strings/phone-9.sl',
  #   {:name => name_var}, res)

  run_sygus_test('./sygus-strings/phone.sl')

  run_sygus_test('./sygus-strings/reverse-name.sl')

  run_sygus_test('./sygus-strings/univ_1.sl')

  # Below need support for if-then-else. Not a priority to support right now!
  # run_sygus_test('./sygus-strings/univ_2.sl')
  # run_sygus_test('./sygus-strings/univ_3.sl')
  # run_sygus_test('./sygus-strings/univ_4.sl')
  # run_sygus_test('./sygus-strings/univ_5.sl')
  # run_sygus_test('./sygus-strings/univ_6.sl')
end
