local utf8 = require("utf8")
local TAM_GRID = 8

local grid = {}
local fonteTitulo = {}
local fonteGrande = {}
local bancoDePalavras = {}
local palavrasGrandes = {}
local palavrasNivel = { "GOLFINHO", "MEDO", "FARINHA", "CHUVA", "RATO", "BRASIL", "FOGÃO", "GIRAFA", "CHAPA" }
local palavrasAlocadas = {}
local carregarBancoDePalavras
local inicializarJogo
local utf8_sub

function love.load()
	-- Configuração da tela para alta resolução e visibilidade
	love.window.setMode(1280, 800)
	-- Carregar banco de palavras
	carregarBancoDePalavras("palavras.txt")

	-- Fontes nativas grandes para acessibilidade
	fonteGrande = love.graphics.newFont(40)
	fonteTitulo = love.graphics.newFont(48)

	-- Cria a grade vazia
	-- for y = 1, TAM_GRID do
	-- 	grid[y] = {}
	-- 	for x = 1, TAM_GRID do
	-- 		grid[y][x] = "-"
	-- 	end
	-- end
	--
	-- Inicia o jogo no nível fácil por padrão
	inicializarJogo("facil")
end

function inicializarJogo(dificuldade)
	local qtdPalavras = 8
	if dificuldade == "médio" then
		qtdPalavras = 9
	end
	if dificuldade == "difícil" then
		qtdPalavras = 10
	end

	-- Cria a grade vazia
	for y = 1, TAM_GRID do
		grid[y] = {}
		for x = 1, TAM_GRID do
			grid[y][x] = {
				letra = nil,
				revelada = false,
				idPalavra = {},
			}
		end
	end

	-- Sorteia palavras sem repetir
	math.randomseed(os.time())
	local bancoCopia = { unpack(bancoDePalavras) }
	-- Garante uma palavra grande
	palavrasNivel = {}
	local idx = math.random(1, #palavrasGrandes)
	table.insert(palavrasNivel, palavrasGrandes[idx])
	for i = 1, qtdPalavras - 1 do
		_ = i
		if #bancoCopia == 0 then
			break
		end
		repeat
			idx = math.random(1, #bancoCopia)
		until bancoCopia[idx] ~= palavrasNivel[1]
		local palavra = table.remove(bancoCopia, idx)
		table.insert(palavrasNivel, palavra)
	end

	-- Insere as palavras na grade
	-- Insere a primeira palavra, horizontalmente no meio da grade
	-- row = math.floor(TAM_GRID / 2) e col = 1
	for c = 1, utf8.len(palavrasNivel[1]) do
		grid[math.floor(TAM_GRID / 2)][c] = {
			letra = utf8_sub(palavrasNivel[1], c, c),
			revelada = false,
			idPalavra = { 1 },
		}
	end
	-- Adiciona a palavra em palavrasAlocadas
	palavrasAlocadas[1] = {
		text = palavrasNivel[1],
		direction = "horizontal",
		startRow = math.floor(TAM_GRID / 2),
		startCol = 1,
		solved = false,
	}
	-- Insere palavras restantes na grade
	for ix = 2, #palavrasNivel do
		local podeInserir, xx, yy

		-- Checa se pode inserir a palavra na vertical
		for x = 1, TAM_GRID do
			xx = x
			for y = 1, TAM_GRID - utf8.len(palavrasNivel[ix]) do
				yy = y
				--podeInserir = true
				for c = 1, utf8.len(palavrasNivel[ix]) do
					-- Checa se existe palavra antes ou depois
					if c == 1 then
						if y + c - 2 > 0 then
							local celula_pri = grid[y + c - 2][x]
							if celula_pri.letra ~= nil then
								podeInserir = false
								break
							end
						end
						if y + utf8.len(palavrasNivel[ix]) <= TAM_GRID then
							local celula_pos = grid[y + utf8.len(palavrasNivel[ix])][x]
							if celula_pos.letra ~= nil then
								podeInserir = false
								break
							end
						end
					end
					-- Checa se existe plavra adjacente na esquerda ou direita
					local celula = grid[y + c - 1][x]
					if x - 1 > 0 then
						local celula_esq = grid[y + c - 1][x - 1]
						if
							celula_esq.letra ~= nil
							and celula_esq.idPalavra ~= nil
							and palavrasAlocadas[celula_esq.idPalavra[1]].direction == "vertical"
						then
							podeInserir = false
							break
						end
					end
					if x + 1 <= TAM_GRID then
						local celula_dir = grid[y + c - 1][x + 1]
						if
							celula_dir.letra ~= nil
							and celula_dir.idPalavra ~= nil
							and palavrasAlocadas[celula_dir.idPalavra[1]].direction == "vertical"
						then
							podeInserir = false
							break
						end
					end
					-- Checa se a plavra cruza com outra
					if celula and celula.letra ~= nil and celula.letra ~= utf8_sub(palavrasNivel[ix], c, c) then
						podeInserir = false
						break
					end
					if
						celula
						and celula.letra ~= nil
						and celula.letra == utf8_sub(palavrasNivel[ix], c, c)
						and celula.idPalavra ~= nil
						and #celula.idPalavra == 1
						and palavrasAlocadas[celula.idPalavra[1]].direction == "horizontal"
					then
						podeInserir = true
					end
				end
				if podeInserir then
					break
				end
			end
			if podeInserir then
				break
			end
		end

		-- Insere palavra na vertical
		if podeInserir then
			for c = 1, utf8.len(palavrasNivel[ix]) do
				local celulaExistente = grid[yy + c - 1][xx]
				if celulaExistente and celulaExistente.letra == utf8_sub(palavrasNivel[ix], c, c) then
					table.insert(celulaExistente.idPalavra, ix)
				else
					grid[yy + c - 1][xx] = {
						letra = utf8_sub(palavrasNivel[ix], c, c),
						revelada = false,
						idPalavra = { ix },
					}
				end
			end
			palavrasAlocadas[ix] = {
				text = palavrasNivel[ix],
				direction = "vertical",
				startRow = yy,
				startCol = xx,
				solved = false,
			}
			--inserida = true
			goto continue
		end
		-- goto continue
		-- Checa se pode inserir a palavra na horizontal
		for y = 1, TAM_GRID do
			yy = y
			for x = 1, TAM_GRID - utf8.len(palavrasNivel[ix]) do -- Tirei +1 pra testar
				xx = x
				--podeInserir = true
				for c = 1, utf8.len(palavrasNivel[ix]) do
					-- Checa se existe palavra antes ou depois
					if c == 1 then
						if x + c - 2 > 0 then
							local celula_pri = grid[y][x + c - 2]
							if celula_pri.letra ~= nil then
								podeInserir = false
								break
							end
						end
						if x + utf8.len(palavrasNivel[ix]) <= TAM_GRID then
							local celula_pos = grid[y][x + utf8.len(palavrasNivel[ix])]
							if celula_pos.letra ~= nil then
								podeInserir = false
								break
							end
						end
					end

					-- Checa se existe plavra adjacente acima ou abaixo
					local celula = grid[y][x + c - 1]
					if y - 1 > 0 then
						local celula_sup = grid[y - 1][x + c - 1]
						if
							celula_sup.letra ~= nil
							and celula_sup.idPalavra ~= nil
							and palavrasAlocadas[celula_sup.idPalavra[1]].direction == "horizontal"
						then
							podeInserir = false
							break
						end
					end
					if y + 1 <= TAM_GRID then
						local celula_inf = grid[y + 1][x + c - 1]
						if
							celula_inf.letra ~= nil
							and celula_inf.idPalavra ~= nil
							and palavrasAlocadas[celula_inf.idPalavra[1]].direction == "horizontal"
						then
							podeInserir = false
							break
						end
					end
					-- Checa se a palavra cruza com outra
					if celula and celula.letra ~= nil and celula.letra ~= utf8_sub(palavrasNivel[ix], c, c) then
						podeInserir = false
						break
					end
					if
						celula
						and celula.letra ~= nil
						and celula.letra == utf8_sub(palavrasNivel[ix], c, c)
						and celula.idPalavra ~= nil
						and #celula.idPalavra == 1
						and palavrasAlocadas[celula.idPalavra[1]].direction == "vertical"
					then
						podeInserir = true
					end
				end
				if podeInserir then
					break
				end
			end
			if podeInserir then
				break
			end
		end

		-- Insere palavra na horizontal
		if podeInserir then
			for c = 1, utf8.len(palavrasNivel[ix]) do
				local celulaExistente = grid[yy][xx + c - 1].idPalavra
				if celulaExistente and celulaExistente.letra == utf8_sub(palavrasNivel[ix], c, c) then
					table.insert(celulaExistente.idPalavra, ix)
				else
					grid[yy][xx + c - 1] = {
						letra = utf8_sub(palavrasNivel[ix], c, c),
						revelada = false,
					}
				end
			end
			palavrasAlocadas[ix] = {
				text = palavrasNivel[ix],
				direction = "horizontal",
				startRow = yy,
				startCol = xx,
				solved = false,
			}
			--inserida = true
		end
		::continue::
		--break
		--end
	end
	-- Debug (exibe grid no terminal)
	for row = 1, TAM_GRID do
		for col = 1, TAM_GRID do
			local letra = " "
			if grid[row][col].letra then
				letra = (grid[row][col]).letra
			end
			io.write(letra .. " ")
		end
		io.write("\n")
	end
end

-- Função para ler o arquivo linha por linha
function carregarBancoDePalavras(caminhoDoArquivo)
	-- Verifica se o arquivo existe dentro da pasta do projeto
	if love.filesystem.getInfo(caminhoDoArquivo) then
		-- love.filesystem.lines percorre o arquivo linha por linha de forma eficiente
		for linha in love.filesystem.lines(caminhoDoArquivo) do
			-- Remove espaços em branco extras nas pontas e ignora linhas vazias
			local palavraLimpa = linha:match("^%s*(.-)%s*$")
			if palavraLimpa ~= "" then
				if #palavraLimpa == TAM_GRID then
					table.insert(palavrasGrandes, palavraLimpa:upper())
				end
				table.insert(bancoDePalavras, palavraLimpa:upper()) -- Salva em maiúsculo
			end
		end
	else
		print("Erro: O arquivo " .. caminhoDoArquivo .. " não foi encontrado!")
	end
end

-- Função útil para cortar strings UTF-8 com segurança
function utf8_sub(s, i, j)
	local start_byte = utf8.offset(s, i)
	local end_byte = j and (utf8.offset(s, j + 1) - 1) or #s
	if start_byte then
		return string.sub(s, start_byte, end_byte)
	end
	return ""
end
