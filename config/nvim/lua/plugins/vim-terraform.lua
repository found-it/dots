return {
  "hashivim/vim-terraform",
  init = function()
    vim.g.terraform_binary_path = "tofu"
    vim.g.terraform_fmt_on_save = true
  end,
}
