macro sunvox_slot_call(method)
  def self.{{method.id}}(slot : Slot)
    _raise_if_slot_closed!(slot)


    success = LibSunVox.{{method.id}}(slot.value) == 0
    raise Exception.new("Cannot #{{{method}}} on slot #{slot}") unless success
  end
end

macro sunvox_slot_call_return(method)
  def self.{{method.id}}(slot : Slot)
    _raise_if_slot_closed!(slot)
    LibSunVox.{{method.id}}(slot.value)
  end
end

