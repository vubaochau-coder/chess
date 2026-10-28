import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/tutorial/lesson.dart';

const String _italianBoard =
    'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R';

/// Nội dung 17 bài hướng dẫn, chia 4 chương (đặc tả T7.1).
abstract final class LessonCatalog {
  static const List<String> chapters = [
    'Các quân cờ',
    'Luật đặc biệt',
    'Kết thúc ván',
    'Mẹo cơ bản',
  ];

  static const List<Lesson> lessons = [
    Lesson(
      id: 'board',
      chapter: 0,
      title: 'Bàn cờ và cách xếp quân',
      subtitle: '64 ô, hàng, cột và vị trí ban đầu',
      body: [
        'Bàn cờ có 64 ô: 8 hàng đánh số 1–8 và 8 cột ghi chữ a–h.',
        'Ô ở góc dưới bên phải luôn là ô sáng.',
        'Trắng xếp quân ở hàng 1–2, Đen ở hàng 7–8.',
        'Hậu đứng trên ô cùng màu với mình. Trắng luôn đi trước.',
        'Hãy chạm vào một quân để xem nó đi được tới đâu.',
      ],
      fen: Fen.initial,
    ),
    Lesson(
      id: 'king',
      chapter: 0,
      title: 'Vua',
      subtitle: 'Đi 1 ô theo mọi hướng',
      body: [
        'Vua đi 1 ô theo mọi hướng: ngang, dọc hoặc chéo.',
        'Vua không được đi vào ô đang bị quân đối phương tấn công.',
        'Mất Vua là thua, nên luôn giữ Vua an toàn.',
      ],
      fen: 'k7/8/8/8/3K4/8/8/8 w - - 0 1',
      challenge: LessonChallenge.reach(
        prompt: 'Đưa Vua tới ô có ngôi sao trong 2 nước',
        target: 'f6',
        maxMoves: 2,
      ),
    ),
    Lesson(
      id: 'queen',
      chapter: 0,
      title: 'Hậu',
      subtitle: 'Quân mạnh nhất: ngang, dọc và chéo',
      body: [
        'Hậu đi ngang, dọc hoặc chéo, bao nhiêu ô cũng được,',
        'miễn là không có quân nào chắn đường.',
        'Hậu là quân mạnh nhất trên bàn cờ.',
      ],
      fen: 'k7/8/8/8/8/8/8/3QK3 w - - 0 1',
      challenge: LessonChallenge.reach(
        prompt: 'Đưa Hậu tới ô có ngôi sao chỉ trong 1 nước',
        target: 'h5',
        maxMoves: 1,
      ),
    ),
    Lesson(
      id: 'rook',
      chapter: 0,
      title: 'Xe',
      subtitle: 'Đi ngang và dọc bao xa tùy ý',
      body: [
        'Xe đi theo hàng ngang hoặc cột dọc, bao nhiêu ô cũng được,',
        'nhưng không nhảy qua quân khác.',
      ],
      fen: 'k7/8/8/8/3R4/8/8/4K3 w - - 0 1',
      challenge: LessonChallenge.reach(
        prompt: 'Đưa Xe tới ô có ngôi sao trong 2 nước',
        target: 'h8',
        maxMoves: 2,
      ),
    ),
    Lesson(
      id: 'bishop',
      chapter: 0,
      title: 'Tượng',
      subtitle: 'Đi chéo, luôn ở một màu ô',
      body: [
        'Tượng đi theo đường chéo, bao nhiêu ô cũng được.',
        'Vì chỉ đi chéo nên Tượng luôn ở trên ô cùng một màu.',
      ],
      fen: 'k7/8/8/8/8/8/8/2B1K3 w - - 0 1',
      challenge: LessonChallenge.reach(
        prompt: 'Đưa Tượng tới ô có ngôi sao chỉ trong 1 nước',
        target: 'h6',
        maxMoves: 1,
      ),
    ),
    Lesson(
      id: 'knight',
      chapter: 0,
      title: 'Mã',
      subtitle: 'Nhảy hình chữ L, vượt qua quân khác',
      body: [
        'Mã đi theo hình chữ L: 2 ô theo một hướng rồi rẽ 1 ô.',
        'Mã là quân duy nhất nhảy qua được quân khác.',
      ],
      fen: 'k7/8/8/8/8/8/8/1N2K3 w - - 0 1',
      challenge: LessonChallenge.reach(
        prompt: 'Đưa Mã tới ô có ngôi sao trong 3 nước',
        target: 'g5',
        maxMoves: 3,
      ),
    ),
    Lesson(
      id: 'pawn',
      chapter: 0,
      title: 'Tốt',
      subtitle: 'Tiến thẳng, ăn chéo',
      body: [
        'Tốt đi thẳng 1 ô; ở nước đầu tiên Tốt được đi 2 ô.',
        'Tốt ăn quân theo đường chéo 1 ô về phía trước.',
        'Tốt không bao giờ đi lùi.',
      ],
      fen: 'k7/8/8/3p4/4P3/8/8/4K3 w - - 0 1',
      challenge: LessonChallenge.playMove(
        prompt: 'Dùng Tốt trắng ăn Tốt đen',
        acceptedMoves: ['e4d5'],
      ),
    ),
    Lesson(
      id: 'castling',
      chapter: 1,
      title: 'Nhập thành',
      subtitle: 'Đưa Vua về nơi an toàn cùng Xe',
      body: [
        'Vua đi 2 ô về phía một Xe, Xe nhảy qua đứng cạnh Vua.',
        'Điều kiện: Vua và Xe đó chưa từng di chuyển, giữa chúng',
        'không có quân nào, Vua không đang bị chiếu và không đi qua',
        'ô bị tấn công.',
      ],
      fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      challenge: LessonChallenge.playMove(
        prompt: 'Chạm Vua rồi chạm ô g1 hoặc c1 để nhập thành',
        acceptedMoves: ['e1g1', 'e1c1'],
      ),
    ),
    Lesson(
      id: 'en_passant',
      chapter: 1,
      title: 'Bắt tốt qua đường',
      subtitle: 'Nước ăn đặc biệt của Tốt',
      body: [
        'Đen vừa đẩy Tốt d7 lên d5, dừng ngay cạnh Tốt e5 của bạn.',
        'Bạn được ăn nó như thể nó chỉ đi 1 ô: Tốt e5 đi chéo tới d6.',
        'Quyền này chỉ có ở ngay nước kế tiếp.',
      ],
      fen: 'k7/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
      challenge: LessonChallenge.playMove(
        prompt: 'Bắt tốt qua đường: đưa Tốt e5 tới d6',
        acceptedMoves: ['e5d6'],
      ),
    ),
    Lesson(
      id: 'promotion',
      chapter: 1,
      title: 'Phong cấp',
      subtitle: 'Tốt tới cuối bàn thành quân mạnh hơn',
      body: [
        'Khi Tốt đi tới hàng cuối cùng, nó được đổi thành Hậu, Xe,',
        'Tượng hoặc Mã. Trong bài này Tốt sẽ thành Hậu;',
        'trong ván thật bạn được tự chọn.',
      ],
      fen: 'k7/4P3/8/8/8/8/8/4K3 w - - 0 1',
      challenge: LessonChallenge.playMove(
        prompt: 'Đưa Tốt lên hàng 8 để phong cấp',
        acceptedMoves: ['e7e8'],
      ),
    ),
    Lesson(
      id: 'check',
      chapter: 2,
      title: 'Chiếu',
      subtitle: 'Vua bị tấn công và cách thoát',
      body: [
        'Chiếu là khi Vua bị quân đối phương tấn công.',
        'Bên bị chiếu bắt buộc phải thoát: đi Vua, chặn đường chiếu',
        'hoặc ăn quân đang chiếu.',
      ],
      fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
      challenge: LessonChallenge.giveCheck(prompt: 'Hãy chiếu Vua đen'),
    ),
    Lesson(
      id: 'checkmate',
      chapter: 2,
      title: 'Chiếu hết',
      subtitle: 'Mục tiêu của ván cờ',
      body: [
        'Chiếu hết là khi Vua bị chiếu và không còn cách nào thoát.',
        'Ai chiếu hết đối phương là người thắng.',
        'Ở đây Vua đen bị chính các Tốt của mình chặn đường.',
      ],
      fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
      challenge: LessonChallenge.checkmate(
        prompt: 'Chiếu hết Vua đen trong 1 nước',
      ),
    ),
    Lesson(
      id: 'draws',
      chapter: 2,
      title: 'Các trường hợp hòa',
      subtitle: 'Hết nước đi, lặp 3 lần, luật 50 nước, thiếu quân',
      body: [
        'Ván cờ hòa khi: bên tới lượt không bị chiếu nhưng hết nước đi;',
        'cùng một thế cờ lặp lại 3 lần; 50 nước liên tiếp không ăn',
        'quân và không đi Tốt; hoặc cả hai bên không đủ quân để chiếu',
        'hết. Trong hình, nếu tới lượt Đen thì Đen hết nước đi:',
        'ván hòa dù Trắng hơn cả một Hậu!',
      ],
      fen: 'k7/2Q5/1K6/8/8/8/8/8 w - - 0 1',
    ),
    Lesson(
      id: 'piece_values',
      chapter: 3,
      title: 'Giá trị các quân',
      subtitle: 'Đổi quân sao cho có lợi',
      body: [
        'Giá trị gần đúng: Tốt 1, Mã 3, Tượng 3, Xe 5, Hậu 9.',
        'Vua là vô giá. Chỉ đổi quân khi bạn nhận lại ít nhất',
        'bằng giá trị đã mất.',
      ],
      fen: 'k7/8/3r4/p7/2N5/8/8/4K3 w - - 0 1',
      challenge: LessonChallenge.playMove(
        prompt: 'Mã ăn được Tốt hoặc Xe: hãy chọn nước có lợi nhất',
        acceptedMoves: ['c4d6'],
      ),
    ),
    Lesson(
      id: 'center',
      chapter: 3,
      title: 'Kiểm soát trung tâm',
      subtitle: 'Vì sao 4 ô giữa quan trọng',
      body: [
        'Bốn ô d4, e4, d5, e5 là trung tâm bàn cờ.',
        'Quân đứng ở trung tâm kiểm soát nhiều ô hơn và dễ chuyển',
        'sang hai cánh. Hãy mở đầu bằng cách đưa Tốt vào trung tâm.',
      ],
      fen: Fen.initial,
      highlights: ['d4', 'e4', 'd5', 'e5'],
      challenge: LessonChallenge.playMove(
        prompt: 'Đưa một Tốt vào trung tâm (e4 hoặc d4)',
        acceptedMoves: ['e2e4', 'd2d4'],
      ),
    ),
    Lesson(
      id: 'development',
      chapter: 3,
      title: 'Phát triển quân',
      subtitle: 'Đưa Mã, Tượng ra sớm',
      body: [
        'Trong khai cuộc, hãy đưa Mã và Tượng rời hàng cuối càng sớm',
        'càng tốt, trước khi đi Hậu.',
        'Tránh đi một quân hai lần khi chưa cần.',
      ],
      fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
      challenge: LessonChallenge.playMove(
        prompt: 'Đưa một Mã hoặc Tượng ra trận',
        acceptedMoves: ['g1f3', 'g1e2', 'b1c3', 'f1c4', 'f1b5', 'f1d3', 'f1e2'],
      ),
    ),
    Lesson(
      id: 'king_safety',
      chapter: 3,
      title: 'Bảo vệ Vua',
      subtitle: 'Nhập thành sớm, giữ hàng Tốt',
      body: [
        'Vua đứng giữa bàn cờ rất dễ bị tấn công.',
        'Hãy nhập thành sớm và hạn chế đẩy các Tốt đứng trước Vua.',
      ],
      fen: '$_italianBoard w KQkq - 4 4',
      challenge: LessonChallenge.playMove(
        prompt: 'Nhập thành để đưa Vua vào nơi an toàn',
        acceptedMoves: ['e1g1'],
      ),
    ),
  ];
}
