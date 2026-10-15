# frozen_string_literal: true

module Capybara
  module Cuprite
    module Devices
      IPHONE_USER_AGENT = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1"
      SAMSUNG_GALAXY_S8_PLUS_USER_AGENT = "Mozilla/5.0 (Linux; Android 8.0.0; SM-G955U Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
      WINDOWS_USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Safari/537.36"

      LIST = {
        iphone_se: {
          window_size: [375, 667], scale_factor: 2, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_xr: {
          window_size: [414, 896], scale_factor: 2, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_12_pro: {
          window_size: [390, 844], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_14: {
          window_size: [390, 844], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_14_plus: {
          window_size: [428, 926], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_14_pro: {
          window_size: [393, 852], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_14_pro_max: {
          window_size: [430, 932], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_15: {
          window_size: [393, 852], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_15_plus: {
          window_size: [430, 932], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_15_pro: {
          window_size: [393, 852], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_15_pro_max: {
          window_size: [430, 932], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_16e: {
          window_size: [390, 844], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_16: {
          window_size: [393, 852], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_16_plus: {
          window_size: [430, 932], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_16_pro: {
          window_size: [402, 874], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        iphone_16_pro_max: {
          window_size: [440, 956], scale_factor: 3, mobile: true,
          user_agent: IPHONE_USER_AGENT
        },
        ipad_mini: {
          window_size: [768, 1024], scale_factor: 2, mobile: true,
          user_agent: "Mozilla/5.0 (iPad; CPU OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1"
        },
        ipad_pro_13: {
          window_size: [1032, 1376], scale_factor: 2, mobile: true,
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15"
        },

        pixel_7: {
          window_size: [412, 915], scale_factor: 2.625, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        pixel_8: {
          window_size: [412, 915], scale_factor: 2.625, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        pixel_8_pro: {
          window_size: [448, 997], scale_factor: 3, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        pixel_8a: {
          window_size: [412, 915], scale_factor: 2.625, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; Pixel 8a) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        pixel_9: {
          window_size: [412, 924], scale_factor: 2.625, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        pixel_9_pro: {
          window_size: [427, 952], scale_factor: 3, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; Pixel 9 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        pixel_9_pro_xl: {
          window_size: [448, 997], scale_factor: 3, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; Pixel 9 Pro XL) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        pixel_10: {
          window_size: [412, 924], scale_factor: 2.625, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 16; Pixel 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        pixel_9_pro_fold: {
          window_size: [412, 922], scale_factor: 2.625, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; Pixel 9 Pro Fold) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },

        samsung_galaxy_s8_plus: {
          window_size: [360, 740], scale_factor: 4, mobile: true,
          user_agent: SAMSUNG_GALAXY_S8_PLUS_USER_AGENT
        },
        samsung_galaxy_s20_ultra: {
          window_size: [412, 915], scale_factor: 3.5, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        samsung_galaxy_a55: {
          window_size: [360, 800], scale_factor: 2.25, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; SM-A556B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        galaxy_z_fold_6: {
          window_size: [412, 968], scale_factor: 2.625, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 14; SM-F956U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        galaxy_z_fold_5: {
          window_size: [344, 882], scale_factor: 2.625, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        samsung_galaxy_a51_71: {
          window_size: [412, 914], scale_factor: 2.625, mobile: true,
          user_agent: SAMSUNG_GALAXY_S8_PLUS_USER_AGENT
        },
        galaxy_tab_s4: {
          window_size: [712, 1138], scale_factor: 2.25, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 8.1.0; SM-T837A) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Safari/537.36"
        },

        surface_pro_7: {
          window_size: [912, 1368], scale_factor: 2, mobile: true,
          user_agent: WINDOWS_USER_AGENT
        },
        surface_pro_10: {
          window_size: [960, 1440], scale_factor: 2, mobile: true,
          user_agent: WINDOWS_USER_AGENT
        },
        surface_duo: {
          window_size: [540, 720], scale_factor: 2.5, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 11.0; Surface Duo) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },

        nest_hub_max: {
          window_size: [1280, 800], scale_factor: 2, mobile: true,
          user_agent: "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Safari/537.36 CrKey/1.54.250320"
        },
        jiophone_2: {
          window_size: [240, 320], scale_factor: 1, mobile: true,
          user_agent: "Mozilla/5.0 (Mobile; LYF/F300B/LYF-F300B-001-01-15-130718-i;Android; rv:48.0) Gecko/48.0 Firefox/48.0 KAIOS/2.5"
        },
        moto_g4: {
          window_size: [360, 640], scale_factor: 3, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 6.0.1; Moto G (4)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        },
        moto_g_power: {
          window_size: [412, 823], scale_factor: 1.75, mobile: true,
          user_agent: "Mozilla/5.0 (Linux; Android 11; moto g power (2022)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%<version>s Mobile Safari/537.36"
        }
      }.freeze

      def self.fetch(name)
        LIST.fetch(name.to_sym) do
          raise ArgumentError, "Unknown device to emulate: #{name.inspect}, use one of #{LIST.keys.join(', ')}"
        end
      end
    end
  end
end
