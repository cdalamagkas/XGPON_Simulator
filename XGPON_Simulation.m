clc; clear;
fprintf('============ XGPON vs XGPON_GT Statistics ============\n');

hasVBR=1; hasCBR=1; %Enable or disable CBR/VBR traffic

Traffic = Form_Traffic( hasVBR, hasCBR );

Sim_Time = 1; %sec
D = [250 500]; %Bytes
N = 4:4:32; %for 8 workers
Samples = 5;
Experiments = length(N);

Final_Packet_Delay = zeros(2,Experiments);
Final_Goodput = zeros(2,Experiments);
Final_Load_Fairness = zeros(2,Experiments);
Final_Delay_Fairness = zeros(2,Experiments);
Final_Packet_Loss_Ratio = zeros(2,Experiments);
Final_PDV = zeros(2,Experiments);
tic;

parfor i = 1:Experiments
   tmp_Packet_Delay = zeros(2,1);
   tmp_Goodput = zeros(2,1);
   tmp_Load_Fairness = zeros(2,1);
   tmp_Delay_Fairness = zeros(2,1);
   tmp_Packet_Loss_Ratio = zeros(2,1);
	tmp_PDV = zeros(2,1);
	
   for k = 1:Samples
      PDT = Set_PDT(N(i));
		[Packet_Delay, Goodput, Load_Fairness, Delay_Fairness, Packet_Loss_Ratio, PDV] = XGPON(Sim_Time, D, N(i), PDT, Traffic, false); %false disables Game Theory
      tmp_Packet_Delay(1) = tmp_Packet_Delay(1) + sum(Packet_Delay)/length(Packet_Delay);
		tmp_Goodput(1) = tmp_Goodput(1) + Goodput;
		tmp_Load_Fairness(1) = tmp_Load_Fairness(1) + Load_Fairness;
		tmp_Delay_Fairness(1) = tmp_Delay_Fairness(1) + Delay_Fairness;
      tmp_Packet_Loss_Ratio(1) = tmp_Packet_Loss_Ratio(1) + sum(Packet_Loss_Ratio)/length(Packet_Loss_Ratio);
		tmp_PDV(1) = tmp_PDV(1) + sum(PDV)/length(PDV);
		
		[Packet_Delay, Goodput, Load_Fairness, Delay_Fairness, Packet_Loss_Ratio, PDV] = XGPON(Sim_Time, D, N(i), PDT, Traffic, true); %true enables Game Theory
		tmp_Packet_Delay(2) = tmp_Packet_Delay(2) + sum(Packet_Delay)/length(Packet_Delay);
		tmp_Goodput(2) = tmp_Goodput(2) + Goodput;
		tmp_Load_Fairness(2) = tmp_Load_Fairness(2) + Load_Fairness;
		tmp_Delay_Fairness(2) = tmp_Delay_Fairness(2) + Delay_Fairness;
      tmp_Packet_Loss_Ratio(2) = tmp_Packet_Loss_Ratio(2) + sum(Packet_Loss_Ratio)/length(Packet_Loss_Ratio);
      tmp_PDV(2) = tmp_PDV(2) + sum(PDV)/length(PDV);
   end
   tmp_Packet_Delay = tmp_Packet_Delay(:)/Samples;
   tmp_Goodput = tmp_Goodput(:)/Samples;
   tmp_Load_Fairness = tmp_Load_Fairness(:)/Samples;
   tmp_Delay_Fairness = tmp_Delay_Fairness(:)/Samples;
   tmp_Packet_Loss_Ratio = tmp_Packet_Loss_Ratio(:)/Samples;
   tmp_PDV = tmp_PDV(:)/Samples;

   Final_Packet_Delay(:,i) = tmp_Packet_Delay;
	Final_Goodput(:,i) = tmp_Goodput;
	Final_Load_Fairness(:,i) = tmp_Load_Fairness;
	Final_Delay_Fairness(:,i) = tmp_Delay_Fairness;
	Final_Packet_Loss_Ratio(:,i) = tmp_Packet_Loss_Ratio;
	Final_PDV(:,i) = tmp_PDV;
	
   fprintf('\n%d ONUs:\n', N(i));
	fprintf('\tXGPON:    Delay=%f msec\t Goodput=%f Mbps\t Load Fairness=%f\t Delay Fairness=%f\n', tmp_Packet_Delay(1)/1e-3, tmp_Goodput(1)*8e-6, tmp_Load_Fairness(1), tmp_Delay_Fairness(1));
	fprintf('\tXGPON-GT: Delay=%f msec\t Goodput=%f Mbps\t Load Fairness=%f\t Delay Fairness=%f\n', tmp_Packet_Delay(2)/1e-3, tmp_Goodput(2)*8e-6, tmp_Load_Fairness(2), tmp_Delay_Fairness(2));

end

Packet_Delay = Final_Packet_Delay;
Goodput = Final_Goodput;
Load_Fairness = Final_Load_Fairness;
Delay_Fairness = Final_Delay_Fairness;
Packet_Loss_Ratio = Final_Packet_Loss_Ratio;
PDV = Final_PDV;

save('results.mat','N','Packet_Delay','Goodput','Load_Fairness','Delay_Fairness','Traffic','Packet_Loss_Ratio','PDV','Sim_Time','D','N','Samples');

fprintf('\n============ End of simulation. Total time: %f ============\n', toc);