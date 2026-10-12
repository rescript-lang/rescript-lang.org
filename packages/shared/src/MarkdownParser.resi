type t
type plugin
type vfile<'a> = {..} as 'a

type result = {
  frontmatter: JSON.t,
  content: string,
}

let parseSync: string => result
