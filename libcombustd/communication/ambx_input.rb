require "singleton"

class AmbxInput
  include Singleton

  POLL_TIMEOUT_MS = 100
  BUFFER_SIZE     = 32   # 0x20 as seen in plugin-ambx start_transactions()
  ENDPOINT_IN     = 0x81

  def initialize
    @callbacks = Hash.new { |h, k| h[k] = [] }
    @running   = false
    @thread    = nil
  end

  def on(event_type, &block)
    @callbacks[event_type] << block
    self
  end

  def start_listening
    return self if @running

    @running = true
    @thread  = Thread.new { poll_loop }
    self
  end

  def stop_listening
    @running = false
    @thread&.join
    @thread = nil
    self
  end

  private

  def poll_loop
    while @running
      handles = Ambx.handles
      next sleep(0.01) if handles.nil? || handles.empty?

      handles.each do |handle|
        next if handle.nil?

        begin
          data = handle.interrupt_transfer(
            endpoint: ENDPOINT_IN,
            dataIn:   BUFFER_SIZE,
            timeout:  POLL_TIMEOUT_MS
          )
          event = RotaryDecoder.decode(data)
          dispatch(event) if event
        rescue LIBUSB::ERROR_TIMEOUT
          # no input, expected
        rescue LIBUSB::ERROR_NO_DEVICE, Errno::ENXIO
          @running = false
          break
        end
      end
    end
  end

  def dispatch(event)
    (@callbacks[event[:type]] + @callbacks[:any]).each { |cb| cb.call(event[:delta]) }
  end
end
