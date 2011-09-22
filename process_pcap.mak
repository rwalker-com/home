dumpdls:=$(wildcard dumpdl_*)

Wls=$(addsuffix /Wl.txt,$(dumpdls))
Wls_clean=$(Wls)

rls=$(addsuffix /rl.txt,$(dumpdls))
rls_clean=$(rls)

tputs=$(addsuffix /a2b_tput.xpl,$(dumpdls))
tputs_clean=$(addsuffix /*_tput.xpl,$(dumpdls))

traffics=$(addsuffix /traffic_bytes.xpl,$(dumpdls))
traffics_clean=$(addsuffix /traffic_*,$(dumpdls))

all: $(Wls) $(rls) $(tputs) $(traffics)

define _dep
$(1):$(2)
endef

depends=$(eval $(_dep))#$(info $(DEPRULE))

$(foreach dir,$(dumpdls),\
	$(call depends,$(dir)/Wl.txt $(dir)/rl.txt $(dir)/a2b_tput.xpl,$(dir)/pcap))

$(Wls):
	cd $(dir $@) && tcptrace -Wl pcap > Wl.txt
Wls_clean:
	rm -f $(Wls_clean)

$(rls):
	cd $(dir $@) && tcptrace -rl pcap > rl.txt
rls_clean:
	rm -f $(rls_clean)

$(tputs):
	cd $(dir $@) && tcptrace -T -A20 pcap
tputs_clean:
	rm -f $(tputs_clean)

$(traffics):
	cd $(dir $@) && tcptrace -xtraffic"-B -i0.2" pcap

traffics_clean:
	rm -f $(traffics_clean)

.PHONY: Wls_clean rls_clean tputs_clean traffics_clean 

clean: Wls_clean rls_clean tputs_clean traffics_clean 
