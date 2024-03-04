import torch


print('CUDA Available', torch.cuda.is_available())

x = torch.randint(1, 100, (100, 100))

res_cpu = x ** 2

x = x.to(torch.device('cuda'))
print('GPU', x.device)

res_gpu = x ** 2

print('======== CPU Result ========')
print(res_cpu)
print('============================')
print('======== GPU Result ========')
print(res_gpu)
print('============================')

print('====== Result Compare ======')
print(torch.equal(res_cpu, res_gpu.cpu()))
