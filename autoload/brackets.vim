let s:plugin_path = expand('<sfile>:p:h:h')

function! brackets#start()
	execute 'cd' fnameescape(s:plugin_path . "/brackets")
	call system("node brackets.js > " . g:brackets_server_log . " &")
	execute 'cd -'
	call brackets#setVars()
	call brackets#setFile()
	call brackets#setupHandlers()
endfunction

function! brackets#setupHandlers()
	autocmd CursorMoved,CursorMovedI *.html,*.js,*.css call brackets#setCursor()
	autocmd TextChanged,TextChangedI * call brackets#bufferChange()
	autocmd BufEnter *.html,*.js,*.css call brackets#setFile()
	autocmd BufWritePost *.js call brackets#evalFile()
endfunction

function! brackets#stop()
	"echom s:server_pid
	"call system("node brackets.js > " . g:brackets_serverlog . " &")
endfunction

function! brackets#sendCurrentBuffer()
	let contents = join(getline(1, '$'), "\n")
	call brackets#sendCommand('b:'.len(contents).':'.contents)
endfunction

function! brackets#evalFile()
	let path = expand('%')
	call brackets#sendCommand('e:'.len(path).':'.path)
endfunction

function! brackets#reload()
	let path = expand('%')
	call brackets#sendCommand('r:'.len(path).':'.path)
endfunction

function! brackets#setFile()
	let path = expand('%:p')
	let bufname = bufname('%')
	let bufnum = bufnr('%')
	let contents = join(getline(1, '$'), "\n")
	call brackets#sendCommand('f:'.len(bufnum).':'.bufnum.':'.len(bufname).':'.bufname.':'.len(path).':'.path.':'.len(&filetype).':'.&filetype.'b:'.len(contents).':'.contents)
endfunction

function! brackets#setVars()
	let cwd = getcwd()
	call brackets#sendCommand('v:'.len(cwd).':'.cwd)
endfunction

function! brackets#bufferChange()
	"one day... this will be better, but for now... just send the whole buffer
	"every time there is a single change
	"this ends up sending WAY to much (like 1Mb/s according to ifconfig) over
	"the internal ip stack and also probably lags vim a lot if requests aren't async call
	call brackets#sendCurrentBuffer()
endfunction

function! brackets#setCursor()
	let line = line('.')
	let column = col('.')
	call brackets#sendCommand('p:'.len(line).':'.line.':'.len(column).':'.column)
endfunction

python3 <<EOF
import sys
import requests
import vim

url = vim.eval("g:brackets_server_path")

def send(msg):
	try:
		requests.post(
			url,
			data=msg)
	except:
		pass #for now
EOF

function! brackets#sendCommand(msg)
python3 <<EOF
send(vim.eval("a:msg"))
EOF
endfunction
