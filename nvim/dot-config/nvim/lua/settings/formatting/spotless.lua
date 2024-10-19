local helpers = require("null-ls.helpers")
local methods = require("null-ls.methods")
local cmd_resolver = require("null-ls.helpers.command_resolver")
--local utils = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return helpers.make_builtin({
    name = "Sptoless formating",
    meta = {
        url = "",
        description = "",
    },
    method = {
        FORMATTING,
        -- RANGE_FORMATTING
    },
    filetypes = {
        "java",
        "xml",
    },
    generator_opts = {
        dynamic_command = function()
            local mvn_wrapper = cmd_resolver.generic("mvnw")
            return function(params)
                return mvn_wrapper(params) or params.command
            end
        end,
        command = "spotless:apply",
        args = {
            "-DspotlessFiles=$FILENAME",
        },
        condition = function(utils)
            return utils.root_has_file({ "mvnw", "pom.xml" })
        end,
        to_stdin = true,
    },
    factory = helpers.formatter_factory,
})
