# encoding: utf-8

require 'gooddata'

GoodData.with_connection('user', 'password') do |client|
  dimension_to_be_replaced = project.datasets('activitydate.dataset.dt')
  replacing_dimension = project.datasets('timeline.dataset.dt')

  fail "The replacing dimension does not seem to be date dimension" unless replacing_dimension.is_date_dimension?
  fail "The dimension to be replaced does not seem to be date dimension" unless dimension_to_be_replaced.is_date_dimension?

  # create a matching map
  attrs = dimension_to_be_replaced.attributes + replacing_dimension.attributes
  groups = attrs.group_by { |a| a.identifier.split('.')[1..-1].join('.') }
  fail "Mapping of attributes cannot be created automatically" unless groups.map {|a, b| b.count}.all? {|x| x == 2 }

  mappings = groups.map {|_, b| [b.first, b.last]}

  metrics.pmap do |metric|
    metric.replace(mappings)
    metric.save
  end

  reports.pmap do |report|
    # resolve labels
    report.replace(mappings)
  end
end