function Test_test_dir_files_are_empty()
  let l:dir = strager#file#make_directory_with_files(['file.txt'])
  let l:file_lines = readfile(strager#path#join([l:dir, 'file.txt']), 'b')
  call assert_equal([''], l:file_lines)
endfunction

function Test_test_dir_files_are_not_opened()
  let l:all_buffers_before = getbufinfo()
  let l:dir = strager#file#make_directory_with_files(['file.txt', 'dir/'])
  let l:all_buffers_after = getbufinfo()
  call assert_equal(l:all_buffers_before, l:all_buffers_after)
endfunction

function Test_test_dir_files_have_content()
  let l:dir = strager#file#make_directory_with_files([
    \ ['file1.txt', "hello world\n"],
    \ ['file2.txt', "  x\ny  \r\nz"],
    \ 'file3.txt',
  \ ])

  let l:file1_lines = readfile(strager#path#join([l:dir, 'file1.txt']), 'b')
  call assert_equal(['hello world', ''], l:file1_lines)

  let l:file2_lines = readfile(strager#path#join([l:dir, 'file2.txt']), 'b')
  call assert_equal(['  x', "y  \r", 'z'], l:file2_lines)

  let l:file3_lines = readfile(strager#path#join([l:dir, 'file3.txt']), 'b')
  call assert_equal([''], l:file3_lines)
endfunction

function! Test_file_exists_case_sensitive()
  let l:Exists = {path -> strager#file#file_exists_case_sensitive(path)}

  call assert_true(l:Exists('/'))

  let l:dir = strager#file#make_directory_with_files([])
  call assert_false(l:Exists(l:dir.'/missing_dir/'))
  call assert_false(l:Exists(l:dir.'/missing_dir/missing_file'))
  call assert_false(l:Exists(l:dir.'/missing_file'))
  call assert_true(l:Exists(l:dir))
  call assert_true(l:Exists(l:dir.'/'))
  call assert_true(l:Exists(l:dir.'/.'))

  let l:dir = strager#file#make_directory_with_files(['file.c'])
  call assert_false(l:Exists(l:dir.'/FILE.C'))
  call assert_false(l:Exists(l:dir.'/File.c'))
  call assert_false(l:Exists(l:dir.'/file.c/'))
  call assert_false(l:Exists(l:dir.'/file.c/.'))
  call assert_false(l:Exists(l:dir.'/file.c/..'))
  call assert_true(l:Exists(l:dir.'/file.c'))

  let l:dir = strager#file#make_directory_with_files(['File.c'])
  call assert_false(l:Exists(l:dir.'/FILE.C'))
  call assert_false(l:Exists(l:dir.'/File.c/'))
  call assert_false(l:Exists(l:dir.'/File.c/.'))
  call assert_false(l:Exists(l:dir.'/File.c/..'))
  call assert_false(l:Exists(l:dir.'/file.c'))
  call assert_true(l:Exists(l:dir.'/File.c'))

  let l:dir = strager#file#make_directory_with_files(['dir/'])
  call assert_false(l:Exists(l:dir.'/Dir'))
  call assert_false(l:Exists(l:dir.'/Dir/'))
  call assert_false(l:Exists(l:dir.'/Dir/..'))
  call assert_false(l:Exists(l:dir.'/Dir/../dir'))
  call assert_true(l:Exists(l:dir.'/dir'))
  call assert_true(l:Exists(l:dir.'/dir/'))
  call assert_true(l:Exists(l:dir.'/dir/..'))
  call assert_true(l:Exists(l:dir.'/dir/../'))
  call assert_true(l:Exists(l:dir.'/dir/../dir'))

  let l:dir = strager#file#make_directory_with_files(['SubDirectory/file.c'])
  call assert_false(l:Exists(l:dir.'/SubDirectory/File.c'))
  call assert_false(l:Exists(l:dir.'/subdirectory'))
  call assert_false(l:Exists(l:dir.'/subdirectory/'))
  call assert_false(l:Exists(l:dir.'/subdirectory/file.c'))
  call assert_true(l:Exists(l:dir.'/SubDirectory'))
  call assert_true(l:Exists(l:dir.'/SubDirectory/'))
  call assert_true(l:Exists(l:dir.'/SubDirectory/file.c'))
endfunction

function! Test_paths_upward()
  call assert_equal(['/'], strager#file#paths_upward('/'))
  call assert_equal([
    \ '/path/to/file',
    \ '/path/to',
    \ '/path',
    \ '/',
  \ ], strager#file#paths_upward('/path/to/file'))
  call assert_equal([
    \ '/path/to/../from/dir',
    \ '/path/to/../from',
    \ '/path/to/..',
    \ '/path/to',
    \ '/path',
    \ '/',
  \ ], strager#file#paths_upward('/path/to/../from/dir'))
  call assert_equal([
    \ '/path/to/dir/',
    \ '/path/to/dir',
    \ '/path/to',
    \ '/path',
    \ '/',
  \ ], strager#file#paths_upward('/path/to/dir/'))
  call assert_equal([
    \ '/path/to/dir/.',
    \ '/path/to/dir',
    \ '/path/to',
    \ '/path',
    \ '/',
  \ ], strager#file#paths_upward('/path/to/dir/.'))

  call assert_equal(['path'], strager#file#paths_upward('path'))
  call assert_equal([
    \ 'path/to/file',
    \ 'path/to',
    \ 'path',
  \ ], strager#file#paths_upward('path/to/file'))
  call assert_equal([
    \ 'path/to/../from/dir',
    \ 'path/to/../from',
    \ 'path/to/..',
    \ 'path/to',
    \ 'path',
  \ ], strager#file#paths_upward('path/to/../from/dir'))
  call assert_equal([
    \ 'path/to/dir/',
    \ 'path/to/dir',
    \ 'path/to',
    \ 'path',
  \ ], strager#file#paths_upward('path/to/dir/'))
  call assert_equal([
    \ 'path/to/dir/.',
    \ 'path/to/dir',
    \ 'path/to',
    \ 'path',
  \ ], strager#file#paths_upward('path/to/dir/.'))

  call assert_equal(['.'], strager#file#paths_upward('.'))
  call assert_equal([
    \ './path/to/file',
    \ './path/to',
    \ './path',
    \ '.',
  \ ], strager#file#paths_upward('./path/to/file'))

  call assert_equal(['..'], strager#file#paths_upward('..'))
  call assert_equal([
    \ '../path/to/file',
    \ '../path/to',
    \ '../path',
    \ '..',
  \ ], strager#file#paths_upward('../path/to/file'))
endfunction

function! Test_find_file_upward_with_glob()
  let l:Find = {path, glob ->
    \ strager#file#find_file_upward_with_glob(path, glob)}

  let l:root_path = strager#file#make_directory_with_files([
    \ 'Makefile',
    \ 'README.txt',
    \ 'src/Makefile',
    \ 'src/main.c',
    \ 'src/test/Makefile',
    \ 'src/test/test0.c',
    \ 'src/test/test1.c',
  \ ])

  " Test missing files.
  call assert_equal([], l:Find(l:root_path, 'doesnotexist'))
  call assert_equal([], l:Find(l:root_path, 'makefile'))
  call assert_equal([], l:Find(l:root_path, 'readme.txt'))
  call assert_equal([], l:Find(l:root_path, 'src/doesnotexist'))

  " Test exact file names.
  call assert_equal([{
    \ 'file_paths': ['Makefile'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'Makefile'))
  call assert_equal([{
    \ 'file_paths': ['README.txt'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'README.txt'))
  call assert_equal([{
    \ 'file_paths': ['src/main.c'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'src/main.c'))
  call assert_equal([{
    \ 'file_paths': ['src'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'src'))
  call assert_equal([{
    \ 'file_paths': ['src/'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'src/'))
  call assert_equal([{
    \ 'file_paths': ['src/test'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'src/test'))
  call assert_equal([{
    \ 'file_paths': ['src/test/'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'src/test/'))

  " Test globs.
  call assert_equal([{
    \ 'file_paths': ['Makefile'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'Make*'))
  call assert_equal([{
    \ 'file_paths': ['src/main.c'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'src/*.c'))
  call assert_equal([{
    \ 'file_paths': ['src/test/test0.c', 'src/test/test1.c'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'src/test/*.c'))
  call assert_equal([{
    \ 'file_paths': ['src/main.c', 'src/test/test0.c', 'src/test/test1.c'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path, 'src/**/*.c'))

  " Test upward searches with exact file names.
  call assert_equal([{
    \ 'file_paths': ['README.txt'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path.'/src', 'README.txt'))
  call assert_equal([{
    \ 'file_paths': ['README.txt'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path.'/src/test', 'README.txt'))
  call assert_equal([{
    \ 'file_paths': ['main.c'],
    \ 'parent_path': l:root_path.'/src',
  \ }], l:Find(l:root_path.'/src/test', 'main.c'))
  call assert_equal([{
    \ 'file_paths': ['src/main.c'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path.'/src', 'src/main.c'))
  call assert_equal([{
    \ 'file_paths': ['src/main.c'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path.'/src/test', 'src/main.c'))
  call assert_equal([{
    \ 'file_paths': ['Makefile'],
    \ 'parent_path': l:root_path.'/src',
  \ }, {
    \ 'file_paths': ['Makefile'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path.'/src', 'Makefile'))
  call assert_equal([{
    \ 'file_paths': ['Makefile'],
    \ 'parent_path': l:root_path.'/src/test',
  \ }, {
    \ 'file_paths': ['Makefile'],
    \ 'parent_path': l:root_path.'/src',
  \ }, {
    \ 'file_paths': ['Makefile'],
    \ 'parent_path': l:root_path,
  \ }], l:Find(l:root_path.'/src/test', 'Makefile'))
endfunction

function! Test_list_directory()
  let l:List = {path -> sort(strager#file#list_directory(path))}

  " Enumerate an empty directory.
  let l:path = strager#file#make_directory_with_files([])
  call assert_equal(['.', '..'], l:List(l:path))

  " Enumerate a directory containing a regular file.
  let l:path = strager#file#make_directory_with_files(['file'])
  call assert_equal(['.', '..', 'file'], l:List(l:path))

  " Enumerate a directory containing a directory.
  let l:path = strager#file#make_directory_with_files(['dir/'])
  call assert_equal(['.', '..', 'dir'], l:List(l:path))

  " Enumerate a directory containing dotfiles.
  let l:path = strager#file#make_directory_with_files(['.vimrc', '.vim/'])
  call assert_equal(['.', '..', '.vim', '.vimrc'], l:List(l:path))

  " Enumerate a directory named with special characters: comma, space, \.
  let l:path = strager#file#make_directory_with_files(['stuff, things, and junk/closet.jpeg'])
  call assert_equal(['.', '..', 'closet.jpeg'], l:List(l:path.'/stuff, things, and junk'))
  let l:path = strager#file#make_directory_with_files(['trailing-slash\/file.txt'])
  call assert_equal(['.', '..', 'file.txt'], l:List(l:path.'/trailing-slash\'))

  " Enumerate a non-existing path.
  let l:path = strager#file#make_directory_with_files([])
  try
    call l:List(l:path.'/dir-does-not-exist')
    call assert_report(
      \ 'Listing files of a non-existing path should have thrown an '.
      \ 'exception, but didn''t',
    \ )
  catch
    call assert_exception('Failed to list files in directory')
  endtry

  " Enumerate a regular file.
  let l:path = strager#file#make_directory_with_files(['file.zip'])
  try
    call l:List(l:path.'/file.zip')
    call assert_report(
      \ 'Listing files of a regular file should have thrown an exception, but '.
      \ 'didn''t',
    \ )
  catch
    call assert_exception('Failed to list files in directory')
  endtry

  " Enumerate the filesystem root.
  let l:names = strager#file#list_directory('/')
  call assert_notequal(-1, index(l:names, '.'))
  call assert_notequal(-1, index(l:names, '..'))
  " Each file should exist.
  for l:name in l:names
    " TODO(strager): Escape wildcards.
    let l:matches = glob('/'.l:name, v:true, v:true, v:true)
    call assert_equal(['/'.l:name], l:matches)
  endfor
endfunction

call strager#test#run_all_tests()
