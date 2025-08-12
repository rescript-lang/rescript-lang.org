/*
 *
 * Color naming convention:
 *
 * Color with opacity:
 * --------
 * grey-80 => grey with 80% opacity
 *
 * Solid Color:
 * --------
 * grey => grey with RGB value
 *
 * Categorizing colors w/ modifiers:
 * --------
 *
 *  -> If we run out of modifiers, we need to define a new
 *     color name!
 *
 * In case with opacity:
 *
 *
 */
export default {
  content: [
    "./src/**/*.{mjs,js,res}",
    "./pages/**/*.{mjs,js,mdx}",
    "./_blogposts/**/*.mdx",
  ],
  theme: {
    extend: {
      colors: {
        gray: {
          5: "#FAFBFC",
          10: "#FAFBFC",
          20: "#EDF0F2",
          30: "#CDCDD6",
          40: "#979AAD",
          60: "#696B7D",
          70: "#3C3D4E",
          80: "#232538",
          90: "#14162C",
          95: "#14162C",
          100: "#0B0D22",
          "5-tr": "rgba(1, 20, 29, 0.02)", //get rid of this
          "10-tr": "rgba(1, 20, 38, 0.02)",
          "60-tr": "rgba(1, 4, 39, 0.6)",
          "80-tr": "rgba(1, 4, 39, 0.8)",
          "90-tr": "rgba(1, 4, 39, 0.95)",
        },
        white: {
          DEFAULT: "#FFFFFF",
          "80-tr": "rgba(255,255,255,0.8)",
          "60-tr": "rgba(255,255,255,0.6)",
          "40-tr": "rgba(255,255,255,0.4)",
        },
        //primary, secondary:
        fire: {
          DEFAULT: "#E6484F", //"50"
          100: "#211332",
          90: "#790C10",
          70: "#C3373d",
          50: "#E6484F",
          30: "#f4646a",
          10: "#fbb8bb",
          5: "#fcf1f1",
          dark: "#E06C75",
        },
        sky: {
          DEFAULT: "#376FDD", //"50"
          90: "#0C2E6F",
          70: "#2258C3",
          30: "#638FE6",
          10: "#DDE8FD",
          5: "#ECF1FC",
        },
        //code-colors start:
        berry: {
          DEFAULT: "#B151DD",
          "dark-50": "#B984DB",
          40: "#A766D0",
          15: "rgba(171, 94, 163, 0.15)",
        },
        water: {
          DEFAULT: "#5E5EDE",
          dark: "#637CC1",
        },
        ocean: {
          dark: "#8AAEC8",
        },
        turtle: {
          DEFAULT: "#02A875",
          dark: "#388B72",
        },
        orange: {
          DEFAULT: "#DD8C1B",
          dark: "#D59B74",
          15: "rgba(224, 172, 0, 0.15)", //old, change
          10: "rgba(224, 172, 0, 0.10)", //old
        },
      },
      /*--- SPACING ---*/
      height: {
        18: "4.5rem", // 72px
        inherit: "inherit",
      },
      minWidth: {
        320: "20rem",
      },
      maxWidth: {
        320: "20rem",
        400: "25rem",
        sm: "30rem", //  480px
        576: "36rem",
        md: "40rem", //  640px
        740: "46.25rem",
        xl: "66.25rem", // 1080px
        1060: "66.25rem",
        1280: "80rem",
        none: "none",
        full: "100%",
      },
      inset: {
        16: "4rem",
        18: "4.5rem",
      },
      spacing: {
        "2/3": "66.666667%",
        "9/16": "56.25%",
        0.75: "0.135rem",
      },
      animation: {
        pulse: "pulse 0.5s cubic-bezier(0.4, 0, 0.6, 1)",
      },
      keyframes: {
        pulse: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: ".5" },
        },
      },
      boxShadow: {
        sm: "0 0.5px 0.5px 0 rgba(0, 0, 0, 0.05)",
      },
    },
    borderRadius: {
      none: "0",
      sm: ".125rem", //2px
      DEFAULT: "0.25rem", //4px
      lg: "0.5rem", //8px
      xl: "1rem", //16px
      full: "9999px", //round
    },
    screens: {
      xs: "599px",
      sm: "576px", //don't use this
      md: "768px", //try to avoid this
      lg: "1024px",
      xl: "1440px",
    },

    /*--- TYPOGRAPHY ---*/
    /* Most of the time we customize the font-sizes,
     so we added the Tailwind default values here for
     convenience */
    fontSize: {
      11: "0.6875rem",
      12: "0.75rem",
      14: "0.875rem",
      16: "1rem",
      18: "1.125rem",
      24: "1.5rem",
      32: "2rem",
      48: "3rem",
      68: "4.25rem",
    },
    fontWeight: {
      normal: 400,
      medium: 500,
      semibold: 600,
      bold: 700,
    },
    lineHeight: {
      none: 1,
      tight: 1.25,
      2: 1.35,
      4: 1.5,
      5: 1.75,
    },
    letterSpacing: {
      tighter: "-0.03em",
      tight: "-0.02em",
      normal: "0",
      wide: "0.075em",
      widest: "0.15em",
    },

    zIndex: {
      0: 0,
      1: 1,
      2: 2,
      3: 3,
      4: 4,
      5: 5,
      10: 10,
      20: 20,
      30: 30,
      40: 40,
      50: 50,
      25: 25,
      50: 50,
      75: 75,
      100: 100,
      auto: "auto",
    },
    /* We override the default font-families with our own default prefs  */
    fontFamily: {
      sans: [
        "Inter",
        "SF Pro Text",
        "Roboto",
        "-apple-system",
        "BlinkMacSystemFont",
        "Helvetica Neue",
        "Arial",
        "sans-serif",
      ],
      mono: [
        "Roboto Mono",
        "SFMono-Regular",
        "Menlo",
        "Segoe UI",
        "Courier",
        "monospace",
      ],
    },
  },
  plugins: [],
}
