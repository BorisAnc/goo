require_relative 'test_case'


class Model1 < Goo::Base::Resource
  model :model1
  validates :prop, :presence => true, :cardinality => { :maximum => 1 }
  unique :prop

  def initialize(attributes = {})
    super(attributes)
  end
end

class Model2 < Goo::Base::Resource
  model :model2
  validates :prop, :presence => true, :cardinality => { :maximum => 1 }
  unique :prop

  def initialize(attributes = {})
    super(attributes)
  end
end

class TestModelDependencies < TestCase

  def initialize(*args)
    super(*args)
    voc = Goo::Naming.get_vocabularies
    if not voc.is_type_registered? :model1
      voc.register_model(:foaf, :model1 , Model1)
      voc.register_model(:foaf, :model2 , Model2)
    else
      raise StandarError, "Error conf unit test" if :model1 != voc.get_model_registry(Model1)[:type]
      raise StandarError, "Error conf unit test" if :model2 != voc.get_model_registry(Model2)[:type]
    end
  end

  def test_model_deps_save
    m1 = Model1.new
    m1.prop = "m1"
    if m1.exists?
      m1_copy = Model1.new
      m1_copy.load(m1.resource_id)
      m1_copy.delete
    end
    m2 = Model2.new
    m2.prop = "m2"
    if m2.exists?
      m2_copy = Model2.new
      m2_copy.load(m2.resource_id)
      m2_copy.delete
    end
    assert_equal false, m1.exists?(reload=true)
    assert_equal false, m2.exists?(reload=true)
    m1.m2 = m2
    assert_instance_of Array, m1.m2
    assert_instance_of Model2, m1.m2[0]
    assert_equal "m2", m1.m2[0].prop
    m1.save
    assert_equal true, m1.persistent?
    assert_equal true, m2.persistent?
    m1_copy = Model1.new
    m1_copy.load(m1.resource_id)
    assert_equal "m1", m1.prop
    assert_equal m2.resource_id.value, m1_copy.m2[0].resource_id.value
    assert_equal true, m1_copy.m2[0].internals.lazy_loaded?
    assert_equal nil, m1_copy.m2[0].prop
    m1_copy.m2[0].load
    assert_equal "m2", m1_copy.m2[0].prop
    assert_equal false, m1_copy.m2[0].internals.lazy_loaded?
    m1.delete
    assert_equal false, m1.exists?(reload=true)
    assert_equal false, m1.persistent?
    assert_equal true, m2.exists?(reload=true)
    assert_equal true, m2.persistent?
    m2.delete
    assert_equal false, m2.exists?(reload=true)
    assert_equal false, m2.persistent?
  end


  def test_model_deps_update
    m1 = Model1.new
    m1.prop = "m1"
    if m1.exists?
      m1_copy = Model1.new
      m1_copy.load(m1.resource_id)
      m1_copy.delete
    end
    m2 = Model2.new
    m2.prop = "m2"
    if m2.exists?
      m2_copy = Model2.new
      m2_copy.load(m2.resource_id)
      m2_copy.delete
    end
    assert_equal false, m1.exists?(reload=true)
    assert_equal false, m2.exists?(reload=true)
    m1.m2 = m2
    assert_instance_of Array, m1.m2
    assert_instance_of Model2, m1.m2[0]
    assert_equal "m2", m1.m2[0].prop

    m1.save
    #modify m2 save m1
    m1.m2[0].new_prop = "m2 new"
    assert_equal true, m1.modified?
    m1.save
    assert_equal 1, count_pattern("#{m1.resource_id.to_turtle} a ?type .")
    assert_equal 1, count_pattern("#{m1.m2[0].resource_id.to_turtle} a ?type .")
    m1.delete
    assert_equal false, m1.exists?(reload=true)
    assert_equal true, m2.exists?(reload=true)
    assert_equal 0, count_pattern("#{m1.resource_id.to_turtle} a ?type .")
    assert_equal 1, count_pattern("#{m2.resource_id.to_turtle} a ?type .")
    m2.delete
    assert_equal false, m1.exists?(reload=true)
    assert_equal false, m2.exists?(reload=true)
    assert_equal 0, count_pattern("#{m1.resource_id.to_turtle} a ?type .")
    assert_equal 0, count_pattern("#{m2.resource_id.to_turtle} a ?type .")
  end

end
