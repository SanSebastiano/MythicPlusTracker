local addonName, addon = ...

-- Must load first (see .toc): establishes the shared `addon` namespace and
-- the global `MPT` alias, and pre-creates `addon.locale` before
-- Locales/locales.xml populates it.
_G["MPT"] = addon
addon.locale = {}
