dumpdls:=$(wildcard dumpdl_*)

Wls=$(addsuffix /Wl.txt,$(dumpdls))
rls=$(addsuffix /rl.txt,$(dumpdls))
tputs=$(addsuffix /a2b_tput.xpl,$(dumpdls))

all: $(Wls) $(rls) $(tputs)

define _dep
$(1):$(2)
endef

depends=$(eval $(_dep))#$(info $(DEPRULE))

$(foreach dir,$(dumpdls),\
	$(call depends,$(dir)/Wl.txt $(dir)/rl.txt $(dir)/a2b_tput.xpl,$(dir)/pcap))

$(Wls):
	cd $(dir $@) && tcptrace -Wl pcap > Wl.txt

$(rls):
	cd $(dir $@) && tcptrace -rl pcap > rl.txt

$(tputs):
	cd $(dir $@) && tcptrace -T -A20 pcap

clean:
	rm -f $(Wls) $(rls) $(tputs)
