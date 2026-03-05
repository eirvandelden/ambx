class Ambx
  module Protocol
    # Product information
    USB_VENDOR_ID  = 0x0471
    USB_PRODUCT_ID = 0x083F
    DEFAULT_USB_DEVICE_IDS = [ [ USB_VENDOR_ID, USB_PRODUCT_ID ] ].freeze
    USB_DEVICE_IDS_ENV = "AMBX_USB_DEVICE_IDS"

    # Usb endpoints
    ENDPOINT_IN  = 0x81
    ENDPOINT_OUT = 0x02
    ENDPOINT_PNP = 0x83

    # -- Commands --

    # Set a single color, for a specific light
    # Params 0xRR 0xGG 0xBB
    # 0xRR = Red color
    # 0xGG = Green color
    # 0xBB = Blue color
    SET_LIGHT_COLOR = 0x03

    # Set a color sequence using delays
    # Params 0xMM 0xMM then a repeated sequence of 0xRR 0xGG 0xBB
    # 0xMM = milliseconds
    # 0xMM = milliseconds
    # 0xRR = Red color
    # 0xGG = Green color
    # 0xBB = Blue color
    SET_TIMED_COLOR_SEQUENCE = 0x72

    # Returns all supported USB vendor/product pairs.
    #
    # Includes built-in IDs and valid IDs parsed from AMBX_USB_DEVICE_IDS.
    #
    # @return [Array<Array<Integer>>] Supported [vendor_id, product_id] pairs.
    def self.supported_usb_device_ids
      (DEFAULT_USB_DEVICE_IDS + usb_device_ids_from_env).uniq
    end

    # Returns true when a USB device ID pair is supported.
    #
    # @param vendor_id [Integer] USB vendor ID.
    # @param product_id [Integer] USB product ID.
    # @return [Boolean] Whether the pair is supported.
    def self.supported_usb_device?(vendor_id, product_id)
      supported_usb_device_ids.include?([ vendor_id, product_id ])
    end

    # Parses AMBX_USB_DEVICE_IDS into [vendor_id, product_id] pairs.
    #
    # @return [Array<Array<Integer>>] Valid parsed ID pairs, excluding malformed values.
    def self.usb_device_ids_from_env
      env_value = ENV.fetch(USB_DEVICE_IDS_ENV, "").strip
      return [] if env_value.empty?

      env_value.split(",").filter_map { |entry| parse_usb_device_id(entry) }
    end
    private_class_method :usb_device_ids_from_env

    # Parses a single "vendor:product" hex entry.
    #
    # Accepts optional 0x/0X prefixes.
    #
    # @param entry [String] Single entry from AMBX_USB_DEVICE_IDS.
    # @return [Array<Integer>, nil] Parsed [vendor_id, product_id] or nil when invalid.
    def self.parse_usb_device_id(entry)
      match = entry.strip.match(/\A(?:0[xX])?([0-9A-Fa-f]{1,4}):(?:0[xX])?([0-9A-Fa-f]{1,4})\z/)
      return nil if match.nil?

      [ match[1].to_i(16), match[2].to_i(16) ]
    end
    private_class_method :parse_usb_device_id
  end
end
