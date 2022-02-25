require "test_helper"

class SygusTest < Minitest::Test
  extend SygusTestRunner

  run_sygus_test('./sygus-strings/bikes.sl')
  run_sygus_test('./sygus-strings/dr-name.sl',
    {:name => ProductDomain.top}, ProductDomain.val(StringPrefix.val("Dr. ", false)))
  run_sygus_test('./sygus-strings/firstname.sl')
  # run_sygus_test('./sygus-strings/initials.sl',
  #   {:name => ProductDomain.top}, ProductDomain.val(StringSuffix.val(".", false), StringLength.val(4, 4)))
  # run_sygus_test('./sygus-strings/lastname.sl')
  # run_sygus_test('./sygus-strings/name-combine-2.sl')
  # run_sygus_test('./sygus-strings/name-combine-3.sl')
  # run_sygus_test('./sygus-strings/name-combine-4.sl')
  run_sygus_test('./sygus-strings/name-combine.sl')
  run_sygus_test('./sygus-strings/phone-1.sl')
  # run_sygus_test('./sygus-strings/phone-10.sl')
  run_sygus_test('./sygus-strings/phone-2.sl')
  # run_sygus_test('./sygus-strings/phone-3.sl')
  run_sygus_test('./sygus-strings/phone-4.sl')
  run_sygus_test('./sygus-strings/phone-5.sl')
  # run_sygus_test('./sygus-strings/phone-6.sl')
  # run_sygus_test('./sygus-strings/phone-7.sl')
  # run_sygus_test('./sygus-strings/phone-8.sl')
  # run_sygus_test('./sygus-strings/phone-9.sl')
  run_sygus_test('./sygus-strings/phone.sl')
  run_sygus_test('./sygus-strings/reverse-name.sl')
  run_sygus_test('./sygus-strings/univ_1.sl')
  # run_sygus_test('./sygus-strings/univ_2.sl')
  # run_sygus_test('./sygus-strings/univ_3.sl')
  # run_sygus_test('./sygus-strings/univ_4.sl')
  # run_sygus_test('./sygus-strings/univ_5.sl')
  # run_sygus_test('./sygus-strings/univ_6.sl')
end
