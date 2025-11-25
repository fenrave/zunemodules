------------------
export type InternalCase<Input, Output> = { [any]: (Input) -> (Output) } & {[Input]: Output}

type MetaCase = {
    __call: (Case: Case, Index: any, Input: any?) -> ... | any,
    __add: (Case: Case, ...any) -> Case
}
------------------

export type Case = setmetatable<InternalCase<any, any>, MetaCase>

local Cases: {[string]: Case} = {}

local function NewCase(Name: string, Options: InternalCase<any, any>): Case

    local returnCase: Case = setmetatable(
        Options,
        {
            __call = function(Case: Case, Index: any, ...: any): ...any
                if ... then
                    return Case[Index](...)
                else
                    return Case[Index]
                end
            end,
            __add = function(mergeTo: Case, toMerge: Case): Case
                for Index,Key in pairs(toMerge) do
                    mergeTo[Index] = Key
                end
                return (mergeTo :: any) :: Case
            end
        } 
    )

    Cases[Name] = returnCase
    return returnCase
end

return NewCase