現在因為方向控制系統故障，
太空船產生逆時鐘90度的方向偏誤，
您必須選擇顯示箭號順時鐘旋轉90度後之按鍵：

看到↑，請按→
看到→，請按↓
看到↓，請按←
看到←，請按↑

準備好請按任意鍵繼續…


answer_directions = np.array(['4', '3', '2', '1'])

mapping on to the response key direction
['up', 'right', 'down', 'left'],

index of the answers
0, 1, 2, 3

stimulus direction index: 0, 1, 2, 3
stimulus direction: up, right, down, left
stimulus orientation degree: 0, 90, 180, 270


sequences are coded as the index of the answers

example 1:

sti sequence (based on answer key orientation): 1, 2, 0, 3 --> 
answer keys (original mapping): 3, 2, 4, 1 --> 
orientation: right, down, up, left
stimulus index: 1, 2, 0, 3 (referring to the answer_directions index)
stimulus orientation: 90, 180, 0, 270 (referring to the key response indicated by answer_directions index)

learning phase --> 
sequence: 1, 2, 0, 3 --> 
answer keys (90 clockwise): 2, 1, 3, 4 --> 
answer orientation: down, left, right, up
stimulus index: 1, 2, 0, 3
stimulus orientation: 90, 180, 0, 270



testing phase --> 
motor test sequence (90 clockwise): 2, 3, 1, 0  --> 
answer keys: 2, 1, 3, 4
direction: down, left, right, up
stimulus index: 2, 3, 1, 0
stimulus orientation: 180, 270, 90, 0


perceptual test sequence (original sequence): 1, 2, 0, 3 -->
answer keys (original mapping): 3, 2, 4, 1
direction: right, down, up, left
stimulus index: 1, 2, 0, 3
stimulus orientation: 90, 180, 0, 270




example 2:

sequence: 3, 0, 2, 1 --> 
answer keys (original mapping): 1, 4, 2, 3 --> 
key direction: left, up, down, right
stimulus index: 3, 0, 2, 1
stimulus orientation: 90, 180, 0, 270


learning phase --> 
sti sequence: 3, 0, 2, 1 -->
answer keys (90 clockwise): 4, 3, 1, 2 --> 
answer index: 0, 1, 3, 2 --> 
direction: up, right, left, down
stimulus index: 3, 0, 2, 1
stimulus orientation: 270, 0, 180, 90



testing phase --> 
motor test sti sequence (90 clockwise): 0, 1, 3, 2  --> 
answer index: 0, 1, 3, 2 --> 
answer keys: 4, 3, 1, 2 -->
direction: up, right, left, down
stimulus index: 0, 1, 3, 2
stimulus orientation: 90, 180, 0, 270


perceptual test sti sequence (original sequence): 3, 0, 2, 1 -->
answer index: 3, 0, 2, 1 --> 
answer keys (original mapping): 1, 4, 2, 3
direction: left, up, down, right
stimulus index: 3, 0, 2, 1
stimulus orientation: 270, 0, 180, 90






