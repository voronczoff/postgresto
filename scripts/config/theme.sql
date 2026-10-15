--liquibase formatted sql
--changeset framework:seed-config-3cb8201e7f runOnChange:true splitStatements:false
INSERT INTO postgresto.${config.table}
  (id, jsondata)
VALUES (
  'theme',
  $json$
  {
    "theme": {
      "modes": {
        "dark": {
          "text": "#e8eaed",
          "error": "#ef5350",
          "hover": "#6BA8E81F",
          "paper": "#000000",
          "divider": "#FFFFFF1F",
          "primary": "#6BA8E8",
          "success": "#66bb6a",
          "warning": "#ffb74d",
          "disabled": "#FFFFFF4C",
          "secondary": "#ff79b0",
          "textMuted": "#aeb6bf",
          "background": "#000000",
          "primaryDark": "#357abd",
          "primaryTint": "#15263b",
          "sidebarText": "#e6e6e6",
          "sidebarHover": "#6BA8E829",
          "textDisabled": "#7a828c",
          "primaryDarkBg": "#2d4a6a",
          "primaryDarker": "#2d6fb3",
          "sidebarActive": "#2d4a6a",
          "sidebarHeader": "#357abd",
          "sidebarGradient": "#4A90E229",
          "primaryTintHover": "#203853",
          "sidebarActiveText": "#ffffff",
          "sidebarBackground": "#0a1628",
          "disabledBackground": "#FFFFFF1F"
        },
        "dawn": {
          "text": "#2a3038",
          "error": "#e53935",
          "hover": "#D4784A1F",
          "paper": "#ece6ea",
          "divider": "#0000001F",
          "primary": "#d4784a",
          "success": "#43a047",
          "warning": "#ffa000",
          "disabled": "#00000042",
          "secondary": "#7a8fb0",
          "textMuted": "#5a6068",
          "background": "#e4dde6",
          "primaryDark": "#b7643d",
          "primaryTint": "#e8dfe2",
          "sidebarText": "#f4f0ec",
          "sidebarHover": "#FFFFFF24",
          "textDisabled": "#9e9e9e",
          "primaryDarkBg": "#53687f",
          "primaryDarker": "#a45332",
          "sidebarActive": "#5a7088",
          "sidebarHeader": "#e08a4a",
          "sidebarGradient": "linear-gradient(180deg, #e08a4a 0%, #c98562 26%, #8a9bb0 58%, #6b7f96 100%)",
          "primaryTintHover": "#d8cbd2",
          "sidebarActiveText": "#ffffff",
          "sidebarBackground": "#6b7f96",
          "disabledBackground": "#0000001F"
        },
        "light": {
          "text": "#222b45",
          "error": "#e53935",
          "hover": "#4A90E214",
          "paper": "#ffffff",
          "divider": "#0000001F",
          "primary": "#4A90E2",
          "success": "#43a047",
          "warning": "#ffa000",
          "disabled": "#00000042",
          "secondary": "#ff4081",
          "textMuted": "#6b778c",
          "background": "#f4f6fb",
          "primaryDark": "#357abd",
          "primaryTint": "#e8f3fc",
          "sidebarText": "#4A90E2",
          "sidebarHover": "#e8f3fc",
          "textDisabled": "#9e9e9e",
          "primaryDarkBg": "#2d4a6a",
          "primaryDarker": "#2d6fb3",
          "sidebarActive": "#4A90E2",
          "sidebarHeader": "#4A90E2",
          "sidebarGradient": "#4A90E226",
          "primaryTintHover": "#c5ddf5",
          "sidebarActiveText": "#f4f6fb",
          "sidebarBackground": "#f4f6fb",
          "disabledBackground": "#0000001F"
        },
        "twilight": {
          "text": "#f0e6e8",
          "error": "#ef5350",
          "hover": "#E8956A24",
          "paper": "#3a3236",
          "divider": "#FFFFFF1F",
          "primary": "#e8956a",
          "success": "#66bb6a",
          "warning": "#ffb74d",
          "disabled": "#FFFFFF4C",
          "secondary": "#d4788c",
          "textMuted": "#b8a8ac",
          "background": "#2e262a",
          "primaryDark": "#c87456",
          "primaryTint": "#443a40",
          "sidebarText": "#f0e6e8",
          "sidebarHover": "#FFBEB41F",
          "textDisabled": "#7a828c",
          "primaryDarkBg": "#6e3540",
          "primaryDarker": "#ad5f50",
          "sidebarActive": "#a34a55",
          "sidebarHeader": "#8f3d48",
          "sidebarGradient": "linear-gradient(180deg, #8f3d48 0%, #6e3540 28%, #403038 58%, #2a2228 100%)",
          "primaryTintHover": "#564850",
          "sidebarActiveText": "#ffffff",
          "sidebarBackground": "#2a2228",
          "disabledBackground": "#FFFFFF1F"
        }
      }
    }
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;
