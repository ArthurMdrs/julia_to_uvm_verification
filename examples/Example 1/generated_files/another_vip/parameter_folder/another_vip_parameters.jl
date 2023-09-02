# Nome da VIP
# vip_name = "some_vip"

# Vetor que define os atributos do packet
packet_vec = [
  [true, "bit  ", " [7:0]", "data_to_send"],
  [true, "logic", "[15:0]", "random_data"]]

# Vetor que define os sinais da interface
signals_if_config = [
  ["logic", "1", "other_ready_o"],
  ["logic", "1", "other_valid_i"],
  ["logic", "[7:0]", "other_address_i"],
  ["logic", "[7:0]", "other_data_o"] ]

# Variável que define se o reset é NBA ou NAA
rst_is_negedge_sensitive = true

# Vetor que define o reset e do clock
if_vec = ["clk", ["rst_n", rst_is_negedge_sensitive], signals_if_config]

# Descomentar e mudar APENAS SE NECESSÁRIO!!!
# Isso irá sobrescrever os vetores definidos em global_vectors.jl
#
# Vetor que define as classes que serão incluídas no package
# pkg_vec = ["sequence_lib", "sequencer", "packet", "agent", "driver"]
# Vetor que define as classes das quais serão geradas os arquivos
# vec_classes = ["sequence_lib", "sequencer", "packet", "pkg", "if", "agent", "monitor"]
#
# Descomentar e mudar APENAS SE NECESSÁRIO!!!
