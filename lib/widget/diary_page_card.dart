import 'package:flutter/material.dart';
import 'package:my_first_app/constants/colors.dart';

class DiaryPageWithComments extends StatelessWidget {
  final Map<String, dynamic> diaryData;
  final bool isMyDiary;
  final int pageIndex;
  final int pageCount;
  final List<Map<String, dynamic>> comments;
  final VoidCallback? onToggleRevealed;
  final VoidCallback? onImageTap;
  final ValueChanged<String>? onSubmitComment;

  const DiaryPageWithComments({
    super.key,
    required this.diaryData,
    required this.isMyDiary,
    required this.pageIndex,
    required this.pageCount,
    required this.comments,
    this.onToggleRevealed,
    this.onImageTap,
    this.onSubmitComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1) 그림 카드
        DiaryPageCard(
          diaryData: diaryData,
          isMyDiary: isMyDiary,
          onToggleRevealed: onToggleRevealed,
          onImageTap: onImageTap,
        ),
        const SizedBox(height: 8),

        // 2) 페이지 인디케이터 바 (카드 바로 아래, 댓글 위)
        PageIndicatorBar(current: pageIndex, total: pageCount, width: 298),
        const SizedBox(height: 8),

        // 3) 댓글 박스 (w 298, h 239, r=20) + 내부 스크롤
        CommentSectionBox(comments: comments, onSubmit: onSubmitComment),
      ],
    );
  }
}

/// 그림 카드 (이전 요구사항 반영: 공개 전엔 상대 탭 막기 + 우상단 자물쇠)
class DiaryPageCard extends StatelessWidget {
  final Map<String, dynamic> diaryData;
  final bool isMyDiary;
  final VoidCallback? onToggleRevealed;
  final VoidCallback? onImageTap;

  const DiaryPageCard({
    super.key,
    required this.diaryData,
    required this.isMyDiary,
    this.onToggleRevealed,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = (diaryData['imageUrl'] as String?)?.trim();
    final bool isRevealed = (diaryData['isRevealed'] as bool?) ?? false;
    final bool isAnonymous = (diaryData['isAnonymous'] as bool?) ?? true;
    final String createdByNickname = (diaryData['createdByNickname'] ?? '')
        .toString();

    final String badgeText = isAnonymous
        ? '익명'
        : (createdByNickname.isEmpty ? '익명' : createdByNickname);

    final bool showLock = !isRevealed && !isMyDiary;
    final bool allowTap = isRevealed || isMyDiary;

    void _handleTap(BuildContext context) {
      if (allowTap) {
        onImageTap?.call();
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('작성자가 아직 공개하지 않았어요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    return Center(
      child: Container(
        width: 298,
        height: 359,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFD9D9D9), // 회색 배경 (라운드 없음)
        ),
        child: Center(
          child: Container(
            width: 268,
            height: 332,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE6E6E6)),
            ),
            child: Stack(
              children: [
                // 이미지
                Positioned.fill(
                  child: InkWell(
                    onTap: () => _handleTap(context),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                const _ImageFallback(),
                          )
                        : const _ImageFallback(),
                  ),
                ),

                // 좌상단 작성자 배지
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 54,
                      minHeight: 27,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000), // 10% 블랙
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OmmaColors.green,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // 우상단: 내 일기 토글 버튼
                if (isMyDiary && onToggleRevealed != null)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: onToggleRevealed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: OmmaColors.green,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000), // 8% 블랙
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          isRevealed ? '숨기기' : '일기 공개',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 우상단: 상대에게만 보이는 잠금 아이콘
                if (showLock)
                  const Positioned(
                    right: 10,
                    top: 10,
                    child: Icon(Icons.lock, size: 18, color: Colors.black54),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.withOpacity(0.7),
        size: 48,
      ),
    );
  }
}

/// 페이지 인디케이터 바: 카드 바로 아래, 폭 298 고정
class PageIndicatorBar extends StatelessWidget {
  final int current;
  final int total;
  final double width;

  const PageIndicatorBar({
    super.key,
    required this.current,
    required this.total,
    this.width = 298,
  });

  @override
  Widget build(BuildContext context) {
    final double height = 10;
    final double progress = (total <= 0)
        ? 0
        : (current.clamp(1, total) / total);

    return SizedBox(
      width: width,
      child: Column(
        children: [
          // 진행 바
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  width: width,
                  height: height,
                  color: const Color(0xFFEDEDED),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: width * progress,
                  height: height,
                  color: OmmaColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 숫자 표시 "n / total"
          Text(
            '$current / $total',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 댓글 박스: w 298, h 239, r=20, 내부 스크롤
class CommentSectionBox extends StatefulWidget {
  final List<Map<String, dynamic>> comments;
  final ValueChanged<String>? onSubmit;

  const CommentSectionBox({super.key, required this.comments, this.onSubmit});

  @override
  State<CommentSectionBox> createState() => _CommentSectionBoxState();
}

class _CommentSectionBoxState extends State<CommentSectionBox> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text);
    _controller.clear();

    // 전송 후 맨 아래로 살짝 딜레이 후 스크롤
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 298,
        height: 239,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2), // 연한 회색
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // 댓글 리스트 (스크롤)
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final c = widget.comments[index];
                  final author = (c['author'] ?? '익명').toString();
                  final content = (c['content'] ?? '').toString();

                  return _CommentBubble(author: author, content: content);
                },
              ),
            ),
            const SizedBox(height: 10),

            // 입력창 (w263, h35, r=50, 연회색)
            SizedBox(
              width: 263,
              height: 35,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED), // 연한 회색 배경
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(fontSize: 13.5, height: 1.2),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '댓글을 입력하세요',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 전송 버튼(아이콘)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Material(
                      color: OmmaColors.green,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _submit,
                        child: const Icon(
                          Icons.send_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final String author;
  final String content;

  const _CommentBubble({
    super.key,
    required this.author,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), // 6% 블랙
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13.5,
            color: Colors.black87,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$author  ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }
}
