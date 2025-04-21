class ProcessLater < ApplicationJob
  def perform(record, method, *args, **kwargs, &block)
    record.send(method, *args, **kwargs, &block)
  end
end
