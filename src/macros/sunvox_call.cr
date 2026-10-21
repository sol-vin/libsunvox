macro sunvox_slot_call(method)
  def self.{{method.id}}(slot : Slot | Int32)
    resolved_slot = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved_slot)

    success = LibSunVox.{{method.id}}(resolved_slot.value) == 0
    raise Exception.new("Cannot #{{{method}}} on slot #{resolved_slot}") unless success
  end
end

macro sunvox_slot_call_return(method)
  def self.{{method.id}}(slot : Slot | Int32)
    resolved_slot = _resolve_slot(slot)
    _raise_if_slot_closed!(resolved_slot)
    LibSunVox.{{method.id}}(resolved_slot.value)
  end
end
