require File.expand_path('../../test_helper', __FILE__)

class ProgressReportBuilderTest < ActiveSupport::TestCase
  
  test "it should create a ProjectProgressReport" do
    
    project = mock()
    project.expects(:kind_of?).with(Project).returns(true)
    
    date_from = 5.days.ago
    date_to = Date.today
    
    report = ProgressReportBuilder.new(project).from(date_from).to(date_to).build
    
    assert report.kind_of?(ProjectProgressReport)
    assert_not_nil report.period.date_from
    assert_not_nil report.period.date_to
    
  end
  
  test "it should create a ProjectVersionProgressReport" do
    
    version = mock()
    version.expects(:kind_of?).with(Project).returns(false)
    
    date_from = 5.days.ago
    date_to = Date.today
    
    report = ProgressReportBuilder.new(version).from(date_from).to(date_to).build
    
    assert report.kind_of?(ProjectVersionProgressReport)
    
  end
  
  test "it should create an instance with params" do
    
    project = mock()
    project.expects(:kind_of?).with(Project).returns(true)
    
    date_from = 5.days.ago
    date_to = Date.today
    
    days_off = { 1 => 2 }
    
    report = ProgressReportBuilder
                .new(project)
                .from(date_from)
                .to(date_to)
                .with(:days_off => days_off)
                .build
    
    assert_equal days_off, report.days_off
    
  end
  
  test "it should format the params hashmaps values and keys to integer if it is needed" do
    
    project = mock()
    project.expects(:kind_of?).with(Project).returns(true)
    
    date_from = 5.days.ago
    date_to = Date.today
    
    days_off = { '1' => '2' }
    days_off_int = { 1 => 2 }
    
    member_occupation = { '1' => '3' }
    member_occupation_int = { 1 => 3 }
    
    report = ProgressReportBuilder
                .new(project)
                .from(date_from)
                .to(date_to)
                .with(:days_off => days_off, 
                      :occupation_persons => member_occupation)
                .build
    
    assert_equal days_off_int, report.days_off
    assert_equal member_occupation_int, report.occupation_persons
    
  end
  
end
